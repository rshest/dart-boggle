library grinder;

import 'dart:math';

import 'dawg.dart';
import 'boggle.dart';

const POOL_SIZE = 1000;
const BEST_SELECTION = 1;

class _Gene {
  List<int> letters;
  int score;
}

class Grinder {
  final int BOARD_W;
  final int BOARD_H;   
  final int NFACES;

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
        board.letterList = g.letters;
        g.score = board.getNonRepeatScore(dawg);
      }
      //  find the best ones
      pool.sort((g1, g2) => g2.score - g1.score);
            
      print("Epoch: ${epoch}, Elapsed: ${stopwatch.elapsed}, Score: ${pool[0].score}, ${pool[1].score}, ${pool[2].score}, , Letters: ${getString(pool[0].letters)}");
      
      //  generate the new epoch
      var tmp = prevPool;
      prevPool = pool;
      pool = tmp;
      
      for (int i = 0; i < BEST_SELECTION; i++) {
        pool[i].letters = prevPool[i].letters;
      }
      for (int i = BEST_SELECTION; i < POOL_SIZE; i++) {
        initGene(pool[i]);
      }
      epoch++;
    }
    return new Boggle(getString(pool[0].letters), BOARD_W, BOARD_H);
  }
  
  initGene(_Gene g) {
    for (int i = 0; i < NFACES; i++) {
      var d = dice[i];
      g.letters[i] = d[random.nextInt(d.length)];
    }
    g.letters.shuffle(random);
  }
}
