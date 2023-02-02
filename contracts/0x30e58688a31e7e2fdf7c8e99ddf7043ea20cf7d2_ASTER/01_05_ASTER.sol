// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Asterales
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                  //
//                                                                                                  //
//    $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$    //
//    [email protected]@@@@@@@@@[email protected]$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$    //
//    [email protected]@BB%%%%%%%[email protected]@[email protected]@$$$$$$$$$$$$$$$$$$$$$$$$$$$$    //
//    [email protected]@BBBBB%%%%%%&&&8%[email protected]@@$$$$$$$$$$$$$$$$$$$$$$$$$    //
//    [email protected]%%%%88&&WMMMWW&&&&&&8%[email protected]@@$$$$$$$$$$$$$$$$$$$$$$    //
//    [email protected]%88&WW#MMW&8&8&&&&&&&%BBBBB%&8%BB%[email protected]$$$$$$$$$$$$$$$$$$$    //
//    $$$$$$$$$$$$$$$$$$$$$$$$$$BBBBBBBB%888&MMMMWW&&&&WWWMMMMM#*cz*urnnzcz*zz***#M8$$$$$$$$$$$$    //
//    [email protected]%88888&#*#*##MMW##M#zcvxt|(\/t\/\(){11(\/[email protected]$$$$$$$$$$    //
//    [email protected]%%%888%88888W******#W*zcvxrjt1(\(|(1}]?_+~~++-?]}11|tv$$$$$$$$$$    //
//    [email protected]@B8888%%%%%%%%&M******zzccxj/ft\||1{[[?-_+<>ii><<<+?[})/j8$$$$$$$$$    //
//    [email protected]%%%%BB%%88%%B8M****#vurrjttt(|(1{}[]]]?-_+++___-?]})|/jxuxB$$$$$$$$    //
//    [email protected]@[email protected]@@BBBBBBBB%&M#MM#rjjft/\|)1}[]?]]]]???-__-?[}{(/[email protected]$$$$$$$    //
//    [email protected]@@@@@BBBBBBBBB%8WWMMMrjjf\(11}}]???-????????_++_-?]}(/tfjrrfj|n$$$$$$$    //
//    [email protected]@BBBBBBB%%%8888W#rnr/1}[[]?-_+++______-______~~+--[1)(\fruuju$$$$$$    //
//    [email protected]@BBBBBBBB%88888W##t)(([-___++~<<<<<<<<<<<~~+__?|rnxxxncz#MM*zz(*$$$$$    //
//    [email protected]%%%BBB%%8888&M##r11)_+~~<>>i>><>iii><>><<<<<~+--_}trrrxxrxnnn/t&$$$$    //
//    $$$$$$$$$$$$$$$$$$$$$BB%%%%%%%%%%%&WMu()))~<<>>iiii>i!!!iii>>>>i>iiiiiiI;!_{|/\|(\/ffj$$$$    //
//    $$$$$$$$$$$$$$$$$$$$$$$%&WMMM&%BBB8W*\((1[!<>>>iiiiiii!!iiiii>><<>>>ii>>iii>~}/tjfffttM$$$    //
//    [email protected]*c*M##zcz*#xt|)1I^,!>iiiiiiii!!!!!!!i>~+___+<<<+?[]?}|fvzxtttx$$$    //
//    [email protected]****uuvjf/fxnczf/\(};```":l>>>ii!!lIIIIli><+?]]]-+!!<}jvur\)jnf/tx$$$    //
//    [email protected]@M*zzcuvrrnuvnxuj///]-_,``````^",,,:::::;I!i<+_-??]~,""":l+-???1t|/#$$$    //
//    [email protected]*W#vnftjt///(_+++>:^````````````````^^":;!<+<;"",,""",:!_{//$$$$    //
//    $$$$$$$$$$$$$$$$$$$$#**zcWM*cvjtft\\|((_+~~~<+~l;,"^````'''````^"""""^^,:,,,,,:;i<}t/W$$$$    //
//    $$$$$$$$$$$$$$$$$$$$%B%&8&*zvuj/|((()(((]~~~<<<<<~++_--_+++~<>!I;,"""`''`^""",:!_{[-[$$$$$    //
//    [email protected]*uj||/()))))))(){]~<<<<<>>>>>ii><~_-?]]]?<:^'''''`",i~l,ii*$$$$$    //
//    $$$$$$$$$$$$$$$$$$$$$$$$$$B#r)((((11(1){11{((|)11[]]-+_~~<<~+_?][[?>;l,`...'''`^:1t8$$$$$$    //
//    $$$$$$$$$$$$$$$$$$$$$$$$$$$$8W*unn)}[}{}(}{1}{[{)}{}}[}((_~_-???]?-<;;;;:^'.'`^~ftv$$$$$$$    //
//    [email protected]@B$$8#*z*#t1))11{)}(}}11][[)1}([{+;;;;::;i<>I;;;;;!lI>[([email protected]$$$$$$$    //
//    [email protected]%@$$8*vnnux\))1?{{111[{())?{{}1{+;::,:,,:,,,!+;;;;[email protected]$$$$$$$$$    //
//    [email protected]%$$$8zxt//jf/(({1[{{{1({{{{)[_!;;;;;;I!iI>[txnx)+II<{uz$$$$$$$$$$$    //
//    [email protected][email protected]%zj|//|jrjt/1())()[11{_iI;;;;Il!i<|vzzzz#W&8&W*[email protected]$$$$$$$$$$$    //
//    $$$$$$$$$$$$$$$$$$$$$$$$$$$$8cj()1)\trjt/t\/(|)]<iii!!i>iiii>ill>~~?})/xc#W*f8$$$$$$$$$$$$    //
//    $$$$$$$$$$$$$$$$$$$$$$$$$$$$&cj\1{11|fxnnurjtt{_~<<~+~~++~>!!i<~-}\jrnunxxxc&$$$$$$$$$$$$$    //
//    [email protected]|}])}{1\jxvvvnxt{?-+++_+~~<>><~-[1\rv*MWWW#x%$$$$$$$$$$$$$$    //
//    $$$$$$$$$$$$$$$$$$$$$$$$$$BBvjf(([)}1(|tfrjxucunt(}]-_+~<>!lll!>>~-}|fxz#*8$$$$$$$$$$$$$$$    //
//    [email protected]&xtt/1{{}[)(\/frrrnvz*zuj|{[-<il;:::;;;l~]})rv#$$$$$$$$$$$$$$$$    //
//    $$$$$$$$$$$$$$$$$$$$$$$$$$$#t/\({}}}11{1|||trnvcz##WMcxt(}?+>!i>+-?})|tnv$$$$$$$$$$$$$$$$$    //
//    $$$$$$$$$$$$$$$$$$$$$$$$$$$c/\(({{[)()\)((\/fnv#88888&WM#cujt//trnuvcz*[email protected]$$$$$$$$$$$$$$$$$    //
//    [email protected]/(1}}{1[}{)||ttruuvvnuvvcz#MW&WWMMMMMWWWW&%$$$$$$$$$$$$$$$$$$$    //
//    $$$$$$$$$$$$$$$$$$$$$$$$$$z/\()1{)}}11((f/\(1)1111(|\tjrrcM8$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$    //
//    $$$$$$$$$$$$$$$$$$$$$$$$$*/)(1){({]{1|t|[_[]--??][}1)(\/tu*$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$    //
//    [email protected]@$$&r/((|)){([]))|{+<><><~?[[][1))(|ju$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$    //
//    [email protected]/\|(\()1){{|\}~>>->i<~-[}[]{{{)\u$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$    //
//    [email protected]%Wn\\/\|((\|()(|)-~>i!i>~+-[}}}}}/\jB$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$    //
//    [email protected]@@@$BBB%8ct\\\/tt//||)(|\?~<>iii<~+[1({{}\xrW$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$    //
//    [email protected]#M&W*rt\ttfffffftff(\1?]+>ii<+~-)(|)1}(\v$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$    //
//    $$$$$$$#njjjrrrvcxf/tt/rjjxnxjjjrt/-+~>-~~____]1)(|1(f\x*8$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$    //
//    [email protected]&crjjjjjt/tfftt/frunucvuxrjn1~>><-]][[?[11/////jfrt\\jnvM&%$$$$$$$$$$$$$$$$$$$$$$$$$    //
//    $$$$%Mujjjfjf\((\\\|\//frrucvunrrr{~<<---_][}}(|tjjtjrnuxjxftt\\|((t%8%$$$$$$$$$$$$$$$$$$$    //
//    [email protected]\((()111)(|trnxnuuuxfj|_~++_-]?}}1)/tjxnfxxrrnuxrufjjrjfxjf/jc8$$$$$$$$$$$$$$$    //
//    $But/t//ttt|)))){]{}})/|trvuvvnxjjtf?~~+~?})[))|jxvufrrtrnxxjruuunxrrxjtftfrcW$$$$$$$$$$$$    //
//    #t/|))(|(|()))1[?]][}|)|(/juvvvvnxrt|-~~~+[11{[)rruujjjjft/fnzurxuxjfrrjjjfffffv%$$$$$$$$$    //
//    ||||)11)11)){[?????--[1)|\/truczcnvxr/)}?_-}{1[{fnxxxfft\ttxzut\/fnxxxjjjjjtffjcz&@$$$$$$$    //
//    ()))1{{11}[]]]]]]]?---?[))\tjjxu**vuuuuxf/|{}[[[(jjrxrj|\/jrj/tf|/jxxxxrjjjftffxu*%@$$$$$$    //
//    \)11{{}}}[[[]]]]]]]--?1}1|||trruvz*##*c*cuuuxt\){|jftf/|)(/\|/|\[email protected]@$$$$    //
//    \){}}}}}}[[[]]]]]]]?]}|\((\/fjfxunc*##MM##*zzvvnj\/|\f\1{{)(111xnrrjjjjfttttttttj*@@@@$$$$    //
//    \1}}}}}}}}[[]]]]]]]])(|/fftxxjjnnnucczc#*MM*ccucccvr/tj\t|}[\[email protected]@[email protected]$    //
//    |)1{{}}}}[[[]]]]]]]]{1|ttftjrnnunvcvuuvuucz##**zzz*cvc#vj()\nnujffftttttttttttttfjv%@[email protected]$    //
//    \\\||()))}[}][[[[}}{1(||\\jxxnuunvzcccuuucuucz###MM*zczzcxjnrfjtftttttttttttttttffuc&[email protected]$$    //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////


contract ASTER is ERC1155Creator {
    constructor() ERC1155Creator("Asterales", "ASTER") {}
}