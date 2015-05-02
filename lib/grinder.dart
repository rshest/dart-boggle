library grinder;

import 'dart:math';

import 'dawg.dart';
import 'boggle.dart';
import 'util.dart';

const POOL_SIZE = 100;
const int MAX_FLIPS = 1;
final int NUM_MUTATE = (POOL_SIZE*0.95).floor();
final int MAX_MUTATE_DEPTH = 3;
final int MAX_PLATEAU_EPOCH = 10000000~/POOL_SIZE;

class _Gene {
  final List<int> letters;
  final List<Die> dice;
    
  int score = 0;
  _Gene(n, dice) : 
    letters = new List<int>(n), 
    dice = new List<Die>(n) {
    for (int i = 0; i < n; i++) {
      this.dice[i] = dice[i];
    }
  }
  
  set letters(Iterable<int> lst) {
    int i = 0;
    for (var c in lst) { 
      letters[i] = c;
      i++;
    }
  }
  
  void copyFrom(_Gene g) { 
    letters = g.letters; 
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
  Dawg dawg;
  Random random;

  Grinder(this.dice, this.dawg, [int w = 5, int h = 5]) :
    BOARD_W = w, BOARD_H = h, NFACES = w*h;

  static getString(List<int> lst) =>
      lst.map((s) => new String.fromCharCode(s)).join('');

   grind(String seed, [int maxEpoch = 1000000]) {
    Boggle board = new Boggle(null, BOARD_W, BOARD_H);
    
    initGene(_Gene g) {
      g.dice.shuffle(random);
      board.initRandom(dawg, g.dice, NFACES, random, random.nextInt(NFACES));
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
        g.score = board.getTotalScore(dawg);
      }
      //  sort by score (best ones first)
      pool.sort((g1, g2) => g2.score - g1.score);

      int score = pool[0].score;

      int sumScore = 0;
      for (int i = 0; i < POOL_SIZE; i++) {
        int s = pool[i].score;
        // to favour better fit genes more
        int ss = pow(10*s/score, 5).toInt(); 
        scores[i] = ss;
        sumScore += ss;
      }

      if (score > bestScore) {
        print("Epoch: ${epoch}[${run}], Elapsed: ${stopwatch.elapsed}, Score: ${score} (${pool[1].score}, ${pool[2].score}), Letters: ${getString(pool[0].letters)}, Dice: [${pool[0].diceStr}]");
        plateau = 0;
        bestScore = score;
      } else {
        plateau++;
        if (plateau > MAX_PLATEAU_EPOCH) {
          //  restart because no improvement for long time
          print("Restarting on epoch ${epoch}");
          print("".padRight(80, "-"));
          bestScore = 0;
          plateau = 0;
          epoch = 0;
          run++;
          pool = initPool(POOL_SIZE);
          continue;
        }
      }

      //  generate the new epoch
      var tmp = prevPool;
      prevPool = pool;
      pool = tmp;

      int curGene = 0;
      //  copy the best gene through
      pool[0].copyFrom(prevPool[0]);
                    
      //  mutation
      for (int i = 0; i < NUM_MUTATE; i++) {
        var g = pool[curGene];
        int p = pickRandomW(random, scores, sumScore);
        g.copyFrom(prevPool[p]);

        int nflips = random.nextInt(MAX_FLIPS) + 1;
        for (int j = 0; j < nflips; j++) {
          int k = random.nextInt(NFACES);
          int mtype = random.nextInt(4);
          if (mtype == 0) {
            //  reinit a part of the board
            int depth = random.nextInt(MAX_MUTATE_DEPTH) + 1;
            board.letterList = g.letters;
            board.initRandom(dawg, g.dice, depth, random, k);
            g.letters = board.faces.map((f) => f.code);
          } else if (mtype == 1) {
            //  rotate a random die
            var d = g.dice[k];
            g.letters[k] = d.faces[random.nextInt(d.faces.length)];
          } else if (mtype == 2) {
            //  swap two random dice
            int k1 = random.nextInt(NFACES);
            int k2 = random.nextInt(NFACES);
            g.swapDice(k1, k2);
          } else if (mtype == 3) {
            //  swap a random die with a random neighbor
            int k = random.nextInt(NFACES);
            int neighbor = board.faces[k].neighbors[random.nextInt(8)];
            if (neighbor != null) {
              g.swapDice(k, neighbor);
            }
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
