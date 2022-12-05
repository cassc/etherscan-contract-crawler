// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: RTF.Multpl.art
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                   //
//                                                                                                                                                                   //
//    :_:,,,'',,,,,,,,,''',,''''..''''''','`` ``````';~~!;,,~^i^,:*|^~;_;;_,~,';_;`,^!~;^:_;~,'';+!~:,^,.;=^^',^<:^=;,:,,__;~,','.```.'''''''''''',,,,,,:,,,,,:~~    //
//    ::,'..''''',,,,,,,,''''',''''',,,','`''```''..'_<~~*|!~;~=*r^^;~~:,;~;,~:,^;,,!I!~;~~~:,~,;!!~;*;*~~?~_:~!,;;',_^=ii!~^^;,'.```.''',,''''''''''',,,'''',,~~    //
//    ,'.....''''''''''',,,'''''',:,~~:::''''.:,.;;~',,!!~+*^,`` `''~~<;_^~,~,~!z=rLnz*+;~'';^~r~''~^;^!+Lr!+|;,!;_,~;,r*:;iL;_''',_'''.'''''''.....'''''.'',',:_    //
//    ''.'...``.'''...`.''''''',:~;_:,~_'.'_;,;:,_~',''..'.`',,,`'.'=^^+;;_^=yKUi=Loj;~~:,~i!~=~,,,;!'.~,~=7<+;~;^;!r^^!,!!!;;:~,~,:,,,:~,.''''...'','''''''',,:,    //
//    ''''''.`````...'.....`..`',_~~~!;__:~~~~,~,`  `'~__,,,;;;:,|;~+^|*;;tQNQg}kKEZ~?x<^_7AkkDyuomn}j<;,+|=^?~''_,;_;+~;~~;;,^r;=<?+~~;;,,.....''''..,,,,,,,,,''    //
//    ,,,,,''..````...''''..`.,~_,;*\z\=!;,,;,,'`''``~;^+?7qRQQQNQjZkUqzi\8QQQQNNK<.  !z|yEgR88iczzQQN7~:!~~^_~_::^^<~~!!!'`,;+~;~_!vz?!;;:,,:,'..```.''.'''''',,    //
//    ,,,,'','''''``...'''',,,:~~~_;^++;|^=^!!r^_'_~^^~~*R%wq8#g8g#iNDwaKbdwo}zi?*=^!!!=*}[email protected]@QQ8DKK5WScf=!!=cY?;;;!rr!~;'~!+c|;;+|*!~~^!!;~~'.``.''..`''',,,,    //
//    ,,,'',',,,'''``````.',_,,~*^~:+<=^+*Li*??=?;!**!;SQgggQQQQQ&Ry^yi*=^r+++==========<<<<==\[email protected]@QNQQNgfzI55v^;!+i\T=_~^^^;~~^^<T*:~<Tx7^~~;~~''```..'''.'.'''    //
//    ''',,,'''',,,'''`  `.,,,;<c*=^^;,^?^:,~~_,:i|izzRQQBQQQQQQQQdf*^^^^^^^rr++++======<<<<<<<*<<[email protected]@@@Q^^Bdm<ihZJv7i<7}\=!r==*<<+;<^,;*=?+^~_~~,``.'''..'.',''    //
//    ''''''''''',,,''.```````.'~icuyfJ|~.      `+\jqQ&qQQQQQQQQXT^^^!!!!!!!^^^^^^^+====<<<<<<<*<**<*5QQgQQQQQQ6m8KIbbZL!xTjhZi7yjuiiixx?~~;!^|?;~',''''.'''''...    //
//    ',,,'''''''',,,'````      `,''.`',`  `  `:;?UQQQQQQQQQQQ6cr^^!;;;;;;;;;!!!^^r+=====<<<<<<********[email protected]@@Q&QqNQQq7;+k#BqhSz7yykSj5yi!^^|77?<^~~''```.''''...    //
//    ',,'''''''',~;,~~.',``.,~,,,:'.`.'.,;;~_:^x%QQN#QQBQQQ&f=r^!!;;~_,,,:_~~;!^^^r+===<<<<<<<<*****??<[email protected]@@@@QQDSRD6?,~;^if7Lr^7i?r|||L**\7v*!~.````````.''.``    //
//    ',,''..','',;~,;;.``.''~;+<!;'';!^^!<;r\zbRQQB#&QQQQQ8\<++^^;;~:,,,,,,:~;!^^rr====<<<<<*****????||?*[email protected]@@@[email protected]@qggJ=!*;i<7\S7<uSyu5}JJLr;~;^;,.``````````....    //
//    ''''```.''''~!^;~'.'_;+!^;,''.~^ri\ISUqD8QDD%[email protected]*<=+r^!;~:,,,,,,~;;^^+===<<<*****??????|||||L||[email protected]@@@@@@Q8NQ&qyv7jm%Axni7jw}**^ivi!,'~~,````.....'..''    //
//    ''''````.```',:,.```.;;,.`'~~_'~r=*7obWB88ND%gQQQQQ%7|?*<==+^!;~~~__~~;!^r+==<****???|||||||[email protected]@@@@@@@QgEZbov}Anz}z*7jwAAE}|;^+^v|;~',~_'.''.```''    //
//    .''.````.''_;;~^,'~;~~,,'~;;,,'~^=~!ukN8QQQBQ%[email protected]|?**<==++^^!!!^^^+=<<**???|||LLLLLLiiiiiii\[email protected]@@Q%yu*=^L^!joT+;~|^;!<~=i=?<*=^+=rr;~~,.``..`.'    //
//    ``````````''_:~~,,'~;=;__;^<!_,,[email protected]\iiL||????**<<<<<<**??|||||Liiiiiiii\\cccTvvv777zT7jWUoq%gN7JZI|Jv..~~L|i~,~rL!;;+;*i<~;Lc|~:_~:''''...    //
//    ''``..`````.`.;*77<LTi+!^r<!;!r!*Yyw8BQW#QQQQ#[email protected]|||||LLLiiiiiii\\\cTTvv77777zzzzzzJJzz}[email protected]@[email protected]_ziJT?<Zkkuz}j7c^<z7ii^^^!^_;^;;~,','''.`    //
//    `..`````.,~,'.,;;_~;,'``.;~':*[email protected]@QQQQBNQhtz7777TTTcccc\\\\c\[email protected]=wbTz}S<Lz*+}xzz\=+;<czv?^~:,'''''    //
//    `..''.'..``.`.`.,,:^**;'.,,,|kdb#[email protected]@QU}tJJzzzzzzzzz7z7z7zzzzzzzzzzzzJtJttxIIYnnnu}}}}[email protected]@@QQQQ#QQQxfjz},~TkjJtfKAUoz*==!=itiv*!_,,,,..`''    //
//    .''''',_,,'~,'~~;=|+|z}=^;[email protected]}}}}[email protected]@QDBQQDSQQgzv^'```<kgS;Ytif\uzv|^!iiLTi!_','```.'    //
//    `..'',:^+~''',,:~L5hi*^[email protected]yy5y55oooZSwEXUqDQQBgK&QQQQQQ#wwI|,' '_*%EjJjyjfii^;;~!LL+_,_,'.`','    //
//    .'''''_,~~~;;;,..!^;=ri^,;;;+|f7}[email protected]XUqbR8QQ&KjNBNQQQQQKXASZy\~=c^<}SqDDoUE}f7i==i^zi=~,''',~'    //
//    ```.'',~!^=?<vi?!|\ic\};,,;;^+<nobQQQ8g&Q&QQQQQ8QQQQQRAkwwmmmmSSSSmSSSSSSSSSmmwwwwwEEEEEEhhkXXXUqbDgNQQQ#&qU8QQQQQQo}#QgXJfXwyI*|iXXUmZj*<nv<<7jyJ^_~:~,,,,    //
//    `` ``.',~~ri*L^~;ii7zy=.`';T||ab8XA8wU8&[email protected]#RqXkkkkkkhkkkkhkkhkkkkkkkXXXUUUUUUU6AqqKDRg#[email protected]#g&QQQQQQQQQQZ=ngBWwobEzwRNRw5yaSn|?*;~!|<~~,'.'''''    //
//    ..'..',~;;^+L=+|7zEWgb7!';|7<[email protected]@[email protected]%R#[email protected]#[email protected]@B&QQQQQQQQQQQQ#QNirnX7~;~~<oEt!?f7it==*=:~=^,.```''...    //
//    ..''.`.~^!*||jj7TL<zza=r;;^zEDxEbET^+=f%[email protected]@[email protected]%%@@QQNRDbqA6AqqKKbKbKbbbbbbbbbddDDdbdDDD%[email protected]@@Q##[email protected]@QQQQRQQg&RZ*^!,,<cx7=*uu7kDgqS|?===~'````..    //
//    ''.````.',~!vn7*zIuDUyz;^LLo5wfY^;[email protected]%[email protected]@@Q&[email protected]&8RUj7^^*i!,_~~,~^+!!<7?L+L|+'```  ``.'    //
//    ''````'~;~;+ic!;=zLuj7vu?=|<fR5,,[email protected]@@@@QQ&N8Wg%ggggggggggRRRR%%gg88N&[email protected]@@@@QQQQQQQQQQQQQQQQQQNQgdj5i^;,,,~^LTz<==+<iyjiT?=~'` ``````    //
//    ''.``...,,~=|LL\|fUfJ7!^;^f8D=::=<Jh8gq}fyaRg#[email protected]@@@QQQQBBQQQQQQBB&##NNNN#&[email protected]@@@@@Q&NQQ8QQgQQQ#QQQQQQQQQQ#8DUI|xyfv^;iihEyi|^|TiiJ^'````````     //
//    ``````.,,,:;?7z\7v=<Tyy*Yb%j+;;^:'~_~;^+hbR8RR%[email protected]@@@@@@[email protected]@@@@[email protected]%QQQQQNDRdmaaf7i|i*<;;~,~r|L<+,,_:'`.'.``    //
//    ..'..`.,~_,,',*uhUKAEEywwj<:~?^.`.,*[email protected]@@[email protected]@@@#[email protected]@@@@@@@[email protected]@@@@@@@@@@@@@@@@QQQQQQQQNQQQQQQWRABQ&%gQ&8QQQQNNq6UamAoyyIyfiI|?iv<++*!;,```..'.`    //
//    '''..`.'','``'~==!;=*!^^^7yXq7!_''~!|z*zK%QQQ8#[email protected]@@[email protected]@@@@@@[email protected]#DWK8Nb&#Q8ggW8K%QBNggKqKhE5tYuTiL|77Y7=|+;,'`..````.`    //
//    .```````',,',;!^<+<xjojz<?c??7jm}777|;;\md8&QQQQ&[email protected]@[email protected]&BQQQQQQQQQQQ&QQQBAE%WQBNBQQ#8Ufyk%bRbqq5}j}yyyI+^+\zz<|i7*;~,...```..    //
//    ..````..':~;;==<=tm}<=i}SzJmRwfJ}5}T^|?ZD#[email protected]@@Q%Uov&[email protected]@QQQQQQQQQQQQR#BQQNQQQQQQQQQQQQQQNRNQNQQQQQQQQQUIizDwUDEkUkjttic7|LL^!^r;!~,.`.....'''    //
//    .'''',,,,_~,_~;=^;*czi<|zSqhzxioyzUD%DDR8#[email protected]@@@@[email protected]@[email protected]@[email protected]&QQQDBQQB%Q8qqRkny6gSqAfJjyyjT^<<^=|I|~,''.````..```    //
//    ..'',,,''''''~r|JXoiI77fjSJ\}[email protected]@[email protected]@[email protected]@[email protected]@[email protected]&QBNREnyf%wjS6R}fUUzzt*|i|=<^!^^;,....'''''```    //
//    .'''.```...,~~!;?**yjzvTvciywxn7nwZXkDD%6oXgQ&[email protected]@[email protected]@QQQQQBQQNQQQQQgQ#QBBNgNNU%NBR88qbqgSuo6jmbS5joAkJJ5j\L*+rivi=!_,,,'..'..'''..    //
//    ..````.''''.''.',~;!^!*nTiz7|+JjwaSEmZRbAD#[email protected]@QQQQQQgQQQQQQQQgWQQQQ8QN8QqaEg88gRgRaEDRjE56IoqY?^^r?+~<T~~|u<<!_~:_,,''''''''.``    //
//    .'....''.```...',:_;^^=!*jj*L}Ytujkkm8qbD6K6qQ%gKQQQQXkAK%[email protected]@@[email protected]@QQQQQQbnADXRmwExJx7Iwf66KR%%EXfXSf?L;=?7<!;;~!!;=7^~,'.```..''''''''.    //
//    ''.`````..``..`.__,,~^^fI|u7tT<ZSSjwbyUgDdobQ8%8N%qDRS}*=i6SdED%bRNQQNg8&[email protected]+EDabWDAEojXkWKRDbDg%Xym}Jv||tiIIc7^:,^?^~,'''.'..``.',,'','    //
//    ','''''..`..''..,_,',:+?+?|xcc7}yoy}uJj7UEwD%qghw6jiz7ZUgNUjISD8RZEN&[email protected]@Q#QQQqN88D88Q%bDwqdN#NyqqkDEI?XDqSE7*7Iu}nzL**\LLiiii=!,,,,,'```..''````.''''    //
//    ,,,,'''..`..'''''',:_,,,;\JfJzL*|7}z|y7T*fAXmExwmUdyzoY|yXqbR#WQdgR8QQQQQQQQQQQQNQQQRRBggQ6j7ZmK}jKUkwm6afv*<*iu}?;~^c=c=?|L^7|\i|r~_~,..``..'''''.`.````.,    //
//    '',,,,'''....'',,,,,,',:~~!it<iJci\iyjcviJwjz|d}}ztLToILwbRRqUgUo6%8B##QQBQQDDQQQQBQQQWQgbD#QgDDwUXXkjEKAvLX7txccY<~;*7=<?|^L\7*|;~_,.....``.''.'''''......    //
//    ,,:,,,,'',''''''''''',,,;;*?<|?7t\*=7<5uckZfyb%Licf*}g?|jJXi^io}tg88%NBNQ%QNR#8#QQQQQQBD&NNgQ#R&%qhwy\7hKjmwUfhYzzJ,~z??tJz7T?;;,,,'.````````.....''''',','    //
//    ,,,,,,,,,,'''''''''''.``.,~^!!<?!=x}*7w\*yv77zJ\JS%NQDyAKUy|}yEUNDdgNBDW%DQNW&NW&BNgXRB8#WDgbDDKwqEiIZ5zL<<=iL?5cL*;==ii|!!!~,'..`...'``.'.``..'.....'',,,,    //
//    ,:___:_:,'',,,',,,,,''.',',,::,';!!<L|z*i*^,,^*yEqEAwJ5RwjAwE5DRDwRdRmKg8RNWRRb}twgXJybgKASjwjjUSZoDynT77=~~;=Lf|v=^=zz!_,.````.'``.'...```.''',,,,,,,,:,:,    //
//    _~~_:,,,,,,,',,',,,,'',,,,,,,'',,'~^!!^Jc~,.'=Jzv*~|zjbX5kDUUcEETStIyDqbqEqRkdSiIy6jEqyRwSI7xffwEaIXv5z*=nIc|!?TIzzx<;!;~,.```````````'''..'',,,,,,,,,,:__:    //
//                                                                                                                                                                   //
//                                                                                                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract RTFMultplART is ERC1155Creator {
    constructor() ERC1155Creator("RTF.Multpl.art", "RTFMultplART") {}
}