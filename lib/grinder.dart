library grinder;

import 'dart:math';

import 'dawg.dart';
import 'boggle.dart';

const POOL_SIZE = 500;
const int MAX_PARENTS = 5;
const int MAX_FLIPS = 10;
final int NUM_PROPAGATE = min(1, (POOL_SIZE*0.01).floor());
final int NUM_CROSSOVER = (POOL_SIZE*0.5).floor();
final int NUM_MUTATE = (POOL_SIZE*0.3).floor();


class _Gene {
  List<int> letters;
  List<int> reorder;
  int score;
  
  get orderedLetters => reorder.map((t) => letters[t]).toList();
}

class Grinder {
  final int BOARD_W, BOARD_H, NFACES;

  List<List<int>> dice;
  Dawg dawg;
  Random random;
  
  Grinder(this.dice, this.dawg, [int w = 5, int h = 5]) :
    BOARD_W = w, BOARD_H = h, NFACES = w*h;
  
  static getString(List<int> lst) =>
      lst.map((s) => new String.fromCharCode(s)).join('');
      
  static parseDice(String desc) =>
    desc.split('\n')
    .map((s) => 
        s.trim().split('').map((t) => t.codeUnitAt(0)).toList())
    .toList();
  
  initPool(int size) {
    var pool = new List<_Gene>(size);
    for (int i = 0; i < size; i++) {
      pool[i] = new _Gene();
      pool[i].letters = new List<int>(NFACES);
      pool[i].reorder = new List<int>(NFACES);
    }
    return pool;
  }
  
  grind(String seed, [int maxEpoch = 1000000]) {
    random = new Random(seed.hashCode);
    List<_Gene> pool = initPool(POOL_SIZE);
    List<_Gene> prevPool = initPool(POOL_SIZE);
        
    //  initialize the pool
    pool.forEach((g) => initGene(g));
    int epoch = 0;
    var board = new Boggle(null, BOARD_W, BOARD_H);
    
    Stopwatch stopwatch = new Stopwatch()..start();
    while (epoch < maxEpoch) {
      // evaluate the genes
      for (var g in pool) {
        board.letterList = g.orderedLetters;
        g.score = board.getNonRepeatScore(dawg);
      }
      //  find the best ones
      pool.sort((g1, g2) => g2.score - g1.score);
            
      print("Epoch: ${epoch}, Elapsed: ${stopwatch.elapsed}, Score: ${pool[0].score}, ${pool[1].score}, ${pool[2].score}, , Letters: ${getString(pool[0].letters)}");
      
      //  generate the new epoch
      var tmp = prevPool;
      prevPool = pool;
      pool = tmp;
      
      int curGene = 0;
      for (int i = 0; i < NUM_PROPAGATE; i++) {
        tmp = pool[curGene];
        pool[curGene] = prevPool[curGene];
        prevPool[curGene] = tmp;
        curGene++;
      }
      //  crossover
      for (int i = 0; i < NUM_CROSSOVER; i++) {
        int numParents = random.nextInt(MAX_PARENTS - 1) + 2;
        //  pick the random parents
        
        //  cross-fuse the cells
        initGene(pool[curGene]);
        curGene++;
      }     
      //  mutation
      for (int i = 0; i < NUM_MUTATE; i++) {
        tmp = pool[curGene];
        pool[curGene] = prevPool[curGene];
        prevPool[curGene] = tmp;
        
        var g = pool[curGene];
        int mtype = random.nextInt(2);
        int nflips = random.nextInt(MAX_FLIPS);
        if (mtype == 1) {
          //  flip a random die with a random neighbor
          initGene(pool[curGene]);
        }
        else {
          //  rotate a random die
          for (int j = 0; j < nflips; j++) {
            int k = random.nextInt(NFACES);
            var d = dice[g.reorder[k]];
            g.letters[k] = d[random.nextInt(d.length)];
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
    return new Boggle(getString(pool[0].orderedLetters), BOARD_W, BOARD_H);
  }
  
  initGene(_Gene g) {
    for (int i = 0; i < NFACES; i++) {
      var d = dice[i];
      g.letters[i] = d[random.nextInt(d.length)];
      g.reorder[i] = i;
    }
    g.reorder.shuffle(random);
  }
}
