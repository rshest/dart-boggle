library grinder;

import 'dart:math';
import 'boggle.dart';

const int MUTATE_INIT = 0;
const int MUTATE_SWAP = 1;
const int MUTATE_ROLL = 2;
const int MUTATE_FLIP = 3;

const POOL_SIZE = 100;
final int NUM_MUTATE = (POOL_SIZE * 0.99).floor();
final int MAX_MUTATE_DEPTH = 10;
final int MAX_PLATEAU_EPOCH = 10000000 ~/ POOL_SIZE;

class _Gene {
  final List<int> letters;
  final List<Die> dice;

  int score = 0;
  _Gene(n, dice)
      : letters = new List<int>(n),
        dice = new List<Die>(n) {
    for (int i = 0; i < n; i++) {
      this.dice[i] = dice[i];
    }
  }

  setLetters(Iterable<int> lst) {
    int i = 0;
    for (var c in lst) {
      letters[i] = c;
      i++;
    }
  }

  void copyFrom(_Gene g) {
    setLetters(g.letters);
    for (int i = 0; i < g.dice.length; i++) dice[i] = g.dice[i];
  }

  void swapDice(int k1, int k2) {
    int c = letters[k1];
    letters[k1] = letters[k2];
    letters[k2] = c;

    Die d = dice[k1];
    dice[k1] = dice[k2];
    dice[k2] = d;
  }

  get diceStr => dice.map((d) => d.id + 1).join(' ');
}

class Grinder {
  final int BOARD_W, BOARD_H, NFACES;

  List<Die> dice;
  Trie trie;
  Random random;

  Grinder(this.dice, this.trie, [int w = 5, int h = 5])
      : BOARD_W = w,
        BOARD_H = h,
        NFACES = w * h;

  static getString(List<int> lst) =>
      lst.map((s) => new String.fromCharCode(s)).join('');

  grind(String seed, [int maxEpoch = 1000000]) {
    Boggle board = new Boggle(null, BOARD_W, BOARD_H);

    initGene(_Gene g) {
      g.dice.shuffle(random);
      board.initRandom(trie, g.dice, NFACES, random, random.nextInt(NFACES));
      for (int i = 0; i < NFACES; i++) {
        g.letters[i] = board.faces[i].code;
      }
    }

    initPool(int size) {
      var pool = new List<_Gene>(size);
      for (int i = 0; i < size; i++) {
        pool[i] = new _Gene(NFACES, dice);
        initGene(pool[i]);
      }
      return pool;
    }

    random = new Random(seed.hashCode);
    List<_Gene> pool = initPool(POOL_SIZE);
    List<_Gene> prevPool = initPool(POOL_SIZE);
    List<int> scores = new List<int>(POOL_SIZE);

    //  initialize the pool
    pool.forEach((g) => initGene(g));
    int epoch = 0;

    Stopwatch stopwatch = new Stopwatch()..start();

    int bestScore = 0;
    int plateau = 0;
    int run = 0;
    while (epoch < maxEpoch) {
      // evaluate the genes
      for (var g in pool) {
        board.letterList = g.letters;
        g.score = board.getTotalScore(trie);
      }
      //  sort by score (best ones first)
      pool.sort((g1, g2) => g2.score - g1.score);

      int score = pool[0].score;

      int sumScore = 0;
      for (int i = 0; i < POOL_SIZE; i++) {
        int s = pool[i].score;
        // favour better fit genes more
        int ss = pow(10 * s / score, 5).toInt();
        scores[i] = ss;
        sumScore += ss;
      }

      if (score > bestScore) {
        print(
            "Epoch: ${epoch}[${run}], Time: ${stopwatch.elapsed}, Score: ${score} (${pool[1].score}, ${pool[2].score}), Letters: ${getString(pool[0].letters)}, Dice: [${pool[0].diceStr}]");
        plateau = 0;
        bestScore = score;
      } else {
        plateau++;
        if (plateau > MAX_PLATEAU_EPOCH) {
          //  restart because no improvement for a long time
          int newSeed = random.nextInt(1000);
          random = new Random(newSeed);
          print("Restarting on epoch ${epoch} with seed ${newSeed}");
          print("".padRight(80, "-"));
          bestScore = 0;
          plateau = 0;
          epoch = 0;
          run++;
          pool = initPool(POOL_SIZE);
          continue;
        }
      }

      //  generate the new epoch (swapping the pool storages)
      var tmp = prevPool;
      prevPool = pool;
      pool = tmp;

      int curGene = 0;
      //  retain the best gene through
      pool[0].copyFrom(prevPool[0]);

      //  mutate the genes
      for (int i = 0; i < NUM_MUTATE; i++) {
        var g = pool[curGene];
        int p = pickRandomW(random, scores, sumScore);
        g.copyFrom(prevPool[p]);

        int depth = random.nextInt(MAX_MUTATE_DEPTH);
        int mutateCell = random.nextInt(NFACES);
        int mtype = random.nextInt(4);
        if (mtype == MUTATE_INIT) {
          //  reinit a path on the board according to probailities
          board.letterList = g.letters;
          board.initRandom(trie, g.dice, depth, random, mutateCell);
          g.setLetters(board.faces.map((f) => f.code));
        } else if (mtype == MUTATE_FLIP) {
          //  rotate a random die
          while (depth > 0) {
            var d = g.dice[mutateCell];
            g.letters[mutateCell] = d.faces[random.nextInt(d.faces.length)];
            int neighbor = board.faces[mutateCell].neighbors[random.nextInt(8)];
            if (neighbor != null) {
              mutateCell = neighbor;
            }
            depth--;
          }
        } else if (mtype == MUTATE_SWAP) {
          //  swap two random dice
          while (depth > 0) {
            int mutateCell1 = random.nextInt(NFACES);
            g.swapDice(mutateCell, mutateCell1);
            mutateCell = mutateCell1;
            depth--;
          }
        } else if (mtype == MUTATE_ROLL) {
          //  swap a chain of random dice with random neighbors
          while (depth > 0) {
            int neighbor = board.faces[mutateCell].neighbors[random.nextInt(8)];
            if (neighbor != null) {
              g.swapDice(mutateCell, neighbor);
              mutateCell = neighbor;
            }
            depth--;
          }
        }

        curGene++;
      }
      //  just randomly init the rest
      for (; curGene < POOL_SIZE; curGene++) {
        initGene(pool[curGene]);
        curGene++;
      }

      epoch++;
    }
    return new Boggle(getString(pool[0].letters), BOARD_W, BOARD_H);
  }
}
