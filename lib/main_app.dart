import 'dart:html';
import 'package:polymer/polymer.dart';
import 'boggle.dart';

const DEFAULT_LETTERS = 'SGECAAREMECGNTDOYSPJNOICD';
const END_PATH = 9;

class Face  extends Object with Observable {
  String letter;
  @observable int direction;  
  Face(this.letter, [this.direction=0]);
}

@CustomTag('main-app')
class MainApp extends PolymerElement {
  @observable List<String> words;
  @observable List<List<Face>> boards;
  @observable int score = 0;
  
  Trie trie;
  Boggle boggle;
  
  makeBoard() => boggle.letterList.map((s)=> new Face(s)).toList();
    
  set letters(String s) {
    if (s == null) s = Boggle.DEFAULT_DICE;
    boggle = new Boggle(s);
    boards = [makeBoard()];
  }
  
  set curWord(String word) {
    var w = (word == null) ? "" : word.trim().split('[')[0].replaceAll('qu', 'q');
    var paths = boggle.getWordPaths(w);
    if (paths.length == 0) {
      boards = [makeBoard()];
      return;
    }
    boards = [];
    for (var path in paths) {
      var board = makeBoard(); 
      final DIR_OFFS = Boggle.offsets(5);
      for (int i = 1; i < path.length; i++) {
        var pc = path[i];
        var pp = path[i - 1];
        board[pc].direction = DIR_OFFS.indexOf(pp - pc) + 1;  
      }
      board[path[0]].direction = END_PATH;
      boards.add(board);
    }
  }
    
  gatherMatchingWords() {
    var mw = boggle.getMatchingWords(trie);
    score = boggle.getTotalScore(trie);   
    var uw = {};
    for (var w in mw) {
      uw.putIfAbsent(w, () => 0);
      uw[w]++;
    }
    words = [];
    for (var w in uw.keys) {
      int nocc = uw[w];
      String qw = w.replaceAll('q', 'qu');
      words.add(nocc == 1 ? qw : "${qw}[${nocc}]"); 
    }
  }
  
  MainApp.created() : super.created()
  {
    //  load the dictionary
    HttpRequest.getString('data/words.txt').then((String dict) {
      letters = Uri.base.queryParameters['letters'];
      trie = new Trie(Trie.parseDictionary(dict));
      gatherMatchingWords();      
      curWord = Uri.base.queryParameters['word'];
    });
  }

  onHovered(MouseEvent event) => curWord = (event.target as Element).innerHtml;
}
