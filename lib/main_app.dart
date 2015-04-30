import 'dart:html';
import 'package:polymer/polymer.dart';
import 'dawg.dart';
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
  
  Dawg dawg;
  Boggle boggle;
  
  makeBoard() => boggle.letterList.map((s)=> new Face(s)).toList();
    
  set letters(String s) {
    boggle = new Boggle(s);
    boards = [makeBoard()];
  }
  
  set curWord(String word) {
    if (word == null) {
      boards = [makeBoard()];
      return;
    }
    var w = word.trim().split('[')[0].replaceAll('qu', 'q');
    var paths = boggle.getWordPaths(w);
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
    var mw = boggle.getMatchingWords(dawg);
    score = boggle.getTotalScore(dawg);   
    var uw = {};
    for (var w in mw) {
      uw.putIfAbsent(w, () => 0);
      uw[w]++;
    }
    words = [];
    for (var w in uw.keys) {
      int nocc = uw[w];
      words.add(nocc == 1 ? w : "${w.replaceAll('q', 'qu')}[${nocc}]"); 
      //  fixup the score to exclude duplicates
      score -= Boggle.rate(w.length)*(nocc - 1);
    }
  }
  
  MainApp.created() : super.created()
  {
    //  load the dictionary
    HttpRequest.getString('data/words.txt').then((String dict) {
      letters = Uri.base.queryParameters['letters'];
      //  parse the dictionary
      var re = new RegExp("q(?!u)");
      var wordList = dict
          .split(' ')
          .where((s) => !re.hasMatch(s))
          .map((s) => s.trim().toLowerCase().replaceAll('qu', 'q'))
          .toList()
          ..sort();
      dawg = new Dawg(wordList);
      gatherMatchingWords();      
      curWord = Uri.base.queryParameters['word'];
    });
  }

  onHovered(MouseEvent event) => curWord = (event.target as Element).innerHtml;
}
