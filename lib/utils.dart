library utils;

import 'dart:math';

//  picks a ranfom element from an array, according to weights
int pickRandomW(Random random, Iterable<int> arr, [int sumScore = null]) {
  if (sumScore == null) {
    sumScore = arr.reduce((a, b) => a + b);
  }
  int w = random.nextInt(sumScore);
  int idx = 0;
  arr.forEach((n) {
    w -= n;
    if (w < 0) return idx;
    idx++;
  });
  return idx;
}

