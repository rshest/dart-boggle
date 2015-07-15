library grinder;

import 'dart:math';
import 'utils.dart';
import 'trie.dart';
import 'boggle.dart';
import 'boggle_init.dart';

const int MUTATE_INIT = 0;
const int MUTATE_SWAP = 1;
const int MUTATE_ROLL = 2;
const int MUTATE_FLIP = 3;
const MUTATE_FREQ = const [5, 25, 15, 20];
final MUTATE_FREQ_SUM = MUTATE_FREQ.reduce((a, b) => a + b);

const POOL_SIZE = 700;
final int NUM_RETAIN = 1;
final int NUM_MUTATE = (POOL_SIZE * 0.90).floor();
final int MAX_MUTATE_DEPTH = 32;
final int MAX_PLATEAU_EPOCH = 1000000 ~/ POOL_SIZE;

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
  int MAX_EPOCH;

  Grinder(this.dice, this.trie,
      [int w = 5, int h = 5, this.MAX_EPOCH = 1000000])
      : BOARD_W = w,
        BOARD_H = h,
        NFACES = w * h;

  static getString(List<int> lst) =>
      lst.map((s) => new String.fromCharCode(s)).join('');

  grind(int seed) {
    var random = new Random(seed);
    int run = 0;
    var bestGenes = new Map<_Gene, int>();
    while (run < 42) {
      print("".padRight(80, "-"));
      print("Starting with seed ${seed}");
      _Gene gene = runGrind(random, run)[0];
      bestGenes[gene] = seed;
      run++;

      int newSeed = random.nextInt(1000000);
      seed = newSeed;
      random = new Random(seed);
    }
    var genes = bestGenes.keys.toList()..sort((a, b) => b.score - a.score);
    int bestScore = genes[0].score;
    int bestSeed = bestGenes[genes[0]];
    //  run with the best seed
    print("Running with the best seed ${bestSeed} (score ${bestScore}):");
    random = new Random(bestSeed);
    runGrind(random, run, null, MAX_PLATEAU_EPOCH*1000);
    run++;

    //  run with the best of the best pool
    print("Running with the best of the best pool, seed ${bestSeed}:");
    random = new Random(bestSeed);
    runGrind(random, run, genes, MAX_PLATEAU_EPOCH*1000);
  }

  runGrind(Random random,
           [int run = 0, List<_Gene> seedPool = null, int maxPlateauEpoch = null]) {
    if (maxPlateauEpoch == null) maxPlateauEpoch = MAX_PLATEAU_EPOCH;
    Boggle board = new Boggle(null, BOARD_W, BOARD_H);

    initGene(_Gene g) {
      g.dice.shuffle(random);
      for (var f in board.faces) f.code = null;
      int nextCell = initPrefix(board, trie, g.dice, NFACES, random, random.nextInt(NFACES));
      //initGreedy(board, trie, g.dice, NFACES - 4, random, nextCell);

      for (int i = 0; i < NFACES; i++) {
        g.letters[i] = board.faces[i].code;
      }
    }

    createPool(int size) {
      var pool = new List<_Gene>(size);
      for (int i = 0; i < size; i++) {
        pool[i] = new _Gene(NFACES, dice);
        initGene(pool[i]);
      }
      return pool;
    }

    List<_Gene> pool = createPool(POOL_SIZE);
    List<_Gene> prevPool = createPool(POOL_SIZE);
    List<int> scores = new List<int>(POOL_SIZE);

    if (seedPool != null) {
      int ngenes = min(seedPool.length, POOL_SIZE);
      for (int i = 0; i < ngenes; i++) pool[i].copyFrom(seedPool[i]);
    }

    Stopwatch stopwatch = new Stopwatch()..start();

    int epoch = 0;
    int bestScore = 0;
    int plateau = 0;
    while (epoch < MAX_EPOCH) {
      // evaluate the genes
      for (var g in pool) {
        board.letterList = g.letters;
        g.score = board.getTotalScore(trie, false);
      }
      //  sort by score (best ones first)
      pool.sort((g1, g2) => g2.score - g1.score);

      int score = pool[0].score;

      int sumScore = 0;
      for (int i = 0; i < POOL_SIZE; i++) {
        int s = pool[i].score;
        // favour better fit genes more
        int ss = pow(10 * s / score, 4).toInt();
        scores[i] = ss;
        sumScore += ss;
      }

      if (score > bestScore) {
        print("Epoch: ${epoch}[${run}], Time: ${stopwatch.elapsed}, "
              "Score: ${score} (${pool[1].score}, ${pool[2].score}), "
              "Letters: ${getString(pool[0].letters)}, "
              "Dice: [${pool[0].diceStr}]");
        plateau = 0;
        bestScore = score;
      } else {
        plateau++;
        if (plateau > maxPlateauEpoch) {
          //  no improvement for long time, bail out
          break;
        }
      }

      //  generate the new epoch (swapping the pool storages)
      var tmp = prevPool;
      prevPool = pool;
      pool = tmp;

      int curGene = 0;
      //  retain the best gene(s) through
      for (; curGene < NUM_RETAIN; curGene++)
        pool[curGene].copyFrom(prevPool[curGene]);

      //  mutate the genes
      for (int i = 0; i < NUM_MUTATE; i++) {
        var g = pool[curGene];
        int p = pickRandomW(random, scores, sumScore);
        g.copyFrom(prevPool[p]);

        int depth = random.nextInt(MAX_MUTATE_DEPTH);
        for (int k = 0; k < depth; k++) {
          board.letterList = g.letters;
          g.score = board.getTotalScore(trie, true);
          /*
          int mutateCell = 0;
          int worstScoreContrib = board.faces[0].scoreContrib;
          for (int i = 1; i < NFACES; i++) {
            int sc = board.faces[i].scoreContrib;
            if (sc < worstScoreContrib) {
              worstScoreContrib = sc;
              mutateCell = i;
            }
          }
           */
          int mutateCell = random.nextInt(NFACES);//pickRandomW(random, board.faces.map((f) => pow(1000 - f.scoreContrib, 2)));
          int mtype = pickRandomW(random, MUTATE_FREQ, MUTATE_FREQ_SUM);
          if (mtype == MUTATE_INIT) {
            initPrefix(board, trie, g.dice, 8, random, mutateCell);
            g.setLetters(board.faces.map((f) => f.code));
          } else if (mtype == MUTATE_FLIP) {
            //  rotate a random die
            Die d = g.dice[mutateCell];
            int bestScore = 0;
            int bestFace = -1;
            for (var f in d.faces) {
              board.faces[mutateCell].code = f;
              int score = board.getTotalScore(trie, false);
              if (score > bestScore) {
                bestScore = score;
                bestFace = f;
              }
            }
            //if (g.score <= bestScore)
              g.letters[mutateCell] = bestFace;
          } else if (mtype == MUTATE_SWAP) {
            //  swap two random dice
            int bestScore = 0;
            int bestCell = -1;
            int curCode = board.faces[mutateCell].code;
            for (int i = 0; i < NFACES; i++) {
              if (i == mutateCell) continue;
              int f = board.faces[i].code;
              board.faces[i].code = curCode;
              board.faces[mutateCell].code = f;
              int score = board.getTotalScore(trie, false);
              if (score > bestScore) {
                bestScore = score;
                bestCell = i;
              }
              board.faces[i].code = f;
            }
            //if (g.score <= bestScore)
              g.swapDice(mutateCell, bestCell);
          } else if (mtype == MUTATE_ROLL) {
            //  swap two neighbors
            int bestScore = 0;
            int bestCell = -1;
            int curCode = board.faces[mutateCell].code;
            for (var neighbor in board.faces[mutateCell].neighbors) {
              if (neighbor == null) continue;
              int f = board.faces[neighbor].code;
              board.faces[neighbor].code = curCode;
              board.faces[mutateCell].code = f;
              int score = board.getTotalScore(trie, false);
              if (score > bestScore) {
                bestScore = score;
                bestCell = neighbor;
              }
              board.faces[neighbor].code = f;
            }
            //if (g.score <= bestScore)
              g.swapDice(mutateCell, bestCell);
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
    return pool;
  }
}
