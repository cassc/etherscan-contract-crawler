// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Re:donuthouse
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                              //
//                                                                                                                                                                                                              //
//                                                                                                                                                                                                              //
//                                                                                                                                                                                                              //
//                                                                                                                                                                                                              //
//                                                                                                                                                                                                              //
//                                                                                                                                                                           .((((,.                            //
//                                                                                                                                                                       (gggNMMMM#-                            //
//                      dMMMMMN+..                                                                                                                                  ...MMMMMMMMMMMMN}                           //
//                    .gMMMMMMMMMNgg,                                                                                                                             .gMMMMMMMMMMMM9WMMNx                          //
//                    .MMMMMndMMMMMMNNN..                                                                                                                    ...dNMMMMMMMME<dMMM3dMMMb                          //
//                    .MMK(MMb` ?WMMMMMMmgx.                                                                                                                (gMMMMMMM#""!`.jMM#>.?TMMNe.                        //
//                    .MMK_?WMR.. ~?TMMMMMMNNm...                                                                                                       ...dMMMMMMMM=`` `..MM#!_..(MMM#~                        //
//                    .MMK...dMM}` `  .TMMMMMMMMmJJ.                                                                                                  .(dMMMMMMMB=` `` ` jMMB3....(MMM#_                        //
//                    .MD!..._?MNs` ``  _??MMMMMMMNm+..                                                                                             .([email protected]>`` `   .dNMM3....._?MMNm;                       //
//                   (MMr.....(TMN,.` ` ` ```?WMMMMMMMN&(,                                                                                         .dMMMMMMB:```` ` ` .MMM#>....~.._dMMN}                       //
//                   (MMr..~..._?WNm< ` `  `   ?<TMMMMMMMNm-                                                                                     (gMMMMMMB!``  `  ` ` .MM#>~......._dMMMl.                      //
//                   (MMr........?MMn. ` `` `` `    7MMMMMMMMm.                                                                                .dMMMMMMB> ` ``  `` ` (MMM9.....~...._dMMMb                      //
//                   (MMr....~....(MMNe_` `  ` `  `  _77MMMMMMNagx                                                                          (ggMMMMMY!` ` `  `` ` ` (gMMI............dMMMb                      //
//                   (MMr..~......_?TMMN{` ` ` `` ` ` `` ?MMMMMMMMNNo.                                                                   ..NMMMMMME!  `` ` ` ` ` ` .dM#>_...~...~....dMMMK-                     //
//                   (MMr......~.....dMMm+` ` `  ` ` `  ` ` ?"TMMMMMMN&&,                                                               ([email protected]^ ` `  ` ` ` ` ` .MM#Y~.......~..~..?TMMNe.                    //
//                   (MMr........~..._?MMNm..` `` ` ` ` `  ` ` _TMMMMMMMNm.                                                            [email protected]!` ` ` `` ` ` ` ` ..MMK................(MMM#~                    //
//                   (MMr..~..~........_7MMMm, ` ` ` ` ` `` `  ` `.TMMMMMMNaJ,                                                       .JMMMMMB= ` `` ` ` ` ` ` ` `jMM#3.....~..~.....~.(MMM#~                    //
//                   (MMr................dMMMb.   ` ` ` ` ` ` ` ` ` _??MMMMMMNm-uNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNm+..........         jNMMMM#>``` `  ` ` ` ` ` `  uNMM3............~....(MMM#~                    //
//                   (MMr....~..~..~......(TMMNx.`` ` `` ` ` ` ` `  ``  ?YWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN&((((((((dMMM#3` `  ` `` ` ` ` ` ` ` dM#>....~..~..........(TMMN&.                   //
//                   (MMr............~....._?WMMNe   `  ` ` ` ` ` ` ` `` ` [email protected]` `` ` ` ` ` ` ` ` ` `.gMMM>.........~..~..~..._dMMN}                   //
//                   (MMr..~...~..~....~....._(MMMN+. ` `  ` ` ` ` ` `  ` ` `                                   7MMMMMMMMMMMMMMMMMMMMb ` `  ` ` ` ` ` ` ` ` ``.MMK_...~..~............._dMMN}                   //
//                   (MMr....................._7MMMMl` ` `` ` ` ` ` ` `` ` ` ` ``````````````````````````````` ` ` `  `  ` ?777777777!` ` `` ` ` ` ` ` ` ` ` (gM9>..........~....~..~.._dMMN}                   //
//                   (MMn-..~...~...~...~..~...._vMMNm. `  ` ` ` ` ` `  ` ` ` `                             ` ` ` ` `` `` ` ` `  ` ` ` ` `  ` ` ` ` ` ` ` ` `jMMr...~.........~........_dMMN}                   //
//                   (MMMK....~...............~...(MMMNa-` `` ` ` ` ` `` ` ` ` `` `` `` `` `` `` `` `` `` `  ` ` ` ` ` ` ` ` ` `` ` ` ` ` `` ` ` ` ` ` ` `  (gMMmx...~..~..~......~...~_dMMN}                   //
//                    ?MMK........~..~...~...._((jNMMMMM} `  ` ` ` ` `  ` ` ` ` `` `` `` `` `` `` `` `` `` `` ` ` ` ` ` ` ` ` `  ` ` ` ` `  ` ` ` ` ` ` ` ` dMMMMMNNNm(--......~......._dMMN}                   //
//                    .MMK..~..........~..._(++MMMYY!` ` ` `` ` ` ` ` `` ` ` `   `  `  `  `  `  `   (JJJ. ` ` ` ` ` ` ` ` ` ` ` ` ` ` ` ` `` ` ` ` ` ` ` ` `` ```?YYMMMMm+J-.......~..._dMMN}                   //
//                    .MMK....~..~......--(qMMMMY! ` ` `` `  ` ` ` ` `  ` ` ` `` ` ` ` ` ` ` ` ` ` .dMMMl. ` ` ` ` ` ` ` ` ` ` ` ` ` ` ` `  ` ` ` ` ` ` ` `  `  ` ` _??MMMNmo--_.....~._dMMM}                   //
//                    .MMK.........~..(JdMMBW3``` ` ` `  ` `` ` ` ` ` `` ` ` ` `` ` ` ` ` ` ` ` ` .MMMHMMb` ` ` ` ` ` ` ` ` ` ` ` ` ` ` ` `` ` ` ` ` ` ` ` `` `  `  ` ` 7WWMMMNe-......_dM#!                    //
//                    .MMK_..~...._(dggMMB^``   ` `` ` ` ` ` ` ` ` ` `  ` ` `   ` ` ` `` ` ` ` `  .MMD(MMNm_ ` ` ` ` ` ` ` ` ` ` ` ` ` ` `  ` ` ` ` ` ` ` `  ``` ` ` ` `   ?7TMMNgm-_._(dM#~                    //
//                    .MMM#:...~.(JMMMMH{   `` ` `  ` ` ` ` ` ` ` ` ` `` ` ` ``  ` ` `  ` ` ` ` `(MM$_(MMM#!` ` ` ` ` ` ` ` ` ` ` ` ` ` ` ` ` ` ` ` ` ` ` ` `  `` ` ` ` `` `  (TMMMNm.(MMM#~                    //
//                     7MM#>..._jgMM97=` ` `  `` ` ` ` ` ` ` ` ` ` ` `  ` ` ` `` ` ` ` ` ` ` ` ``jMMr.._dMNm- ` ` ` ` ` ` ` ` ` ` ` ` ` ` `` ` ` ` ` ` ` ` ` `  ` ` ` ` ` ` ``  ?7TMMNgMMM#~                    //
//                     .dM#>.-([email protected]! ` `` ` ` ` ` ` ` ` ` ` ` ` ` ` `......  `  ` ` ` ` ` ` ` ` .jMMr.._dMMM}` ` ` ` ` ` ` ` ` ......` ` `  ` ` ` ` ` ` ` ` `` ` ` ` ` ` ` `  ` `  _TMMMMD~                     //
//                      dMNagdMMB=` ` `  ` ` ` ` ` ` ` ` ` ` ` ` `  (gMMMMNa+,`` ` ` ` ` ` ` `  dMMMr.._?HMM} ` ` ` ` ` ` ` (++MMMMMm+J.` ` ` ` ` ` ` ` ` `  ` ` ` ` ` ` ` `` `` ` ` (TMMNJ.                    //
//                      dMMMMMMM}` ` ` `` ` ` ` ` ` ` ` ` ` ` ` ` .dMM#C<<<?WMNN&.. ` ` ` ` ` ` dM#C~....dMM}` ` ` ` ` ` ..dMMMM$<?MMMMN{ `` ` ` ` ` ` ` ` `` ` ` ` ` ` ` `  `  ` ` ``.MMM#-                    //
//                      ?MMMMM5`  ` ` `  ` ` ` ` ` ` ` ` ` ` ` ` `.MMM#>.....?WMMMNe- ` ` ` ``  dM#>.....dMMm,` ` ` ` ` (dMM#3....._7MMM}`  ` ` ` ` ` ` ` `  ` ` ` ` ` ` ` ` `` ` ` ` ` ?MMMm,                  //
//                      jNMMD! ` ` ` ` ` ` ` ` ` ` ` ` ` ` ..... `.MM#>~......_?<UMMNs`` ` `   .dM#>.....dMMMb` ` ` `  .dM#C~........dMMNe......  `  ` ` ` `` ` ` ` ` ` ` ` `  ` ` `  ` `_?MMb.                 //
//                     .dMMM#3` ` ` ` ` ` ` ` ` ` ` ` ` .((MMNMNm(JMMK...........?MMMN.. ` ` `.MMM#>...~.dMMMb ` ` ` `.MMM8:....~....?MMMMMMNNMNm(..` ` ` `  ` ` ` ` ` ` ` ` `` ` ` `` ` `.TMM#~                //
//                    .MMM#=! ` ` ` ` ` ` ` ` ` ` ` ` .gMMMMMMMMMMMMMK...~..~....._?MMNm< ` ` .MMM#>.....dMMMb` ` ` `(gMMD........~..(gMMMMMMMMMMMNm+  ` ` ` ` ` ` ` ` ` ` ` ` ` ` `  ` ` ` dMNm-               //
//                   ..MMME~ ` ` ` ` ` ` ` ` ` ` ` ` ..MMK~~~~~~~~?MM5............._dMMM}` `` .MMM#>....._(MMb` ` ` `jMM$_...~......._?MMMMM3~~~TMMMMR` ` ` ` ` ` ` ` ` ` ` ` ` ` ` ` ` ` `` JMNn.              //
//                   (MMMb` ` ` ` ` ` ` ` ` ` ` ` ` `jMMMK..............~....~....._?WMMm+`  `.MMM#>..~...(MMb ` `  (gMMr......~.................?TMMb ` ` ` ` ` ` ` ` ` ` ` ` ` ` ` ` ` ` ``JMMMb              //
//                  .jMMMD ` ` ` ` ` ` ` ` ` ` ` ` `  (MMR-_..............~....~..._dMMMMb` ``.MMM#>......(MMb` ` ` dMMMr........~..~.............(MMb` ` ` ` ` ` ` ` ` ` ` ` ` ` ` ` ` `..dNMMMMb.             //
//                  dMMMm,` ` ` ` ` ` ` ` ` ` ` ` ` ` .MMM#>.....~..~..~.........~...dMMMb `  .MMM#>.....(gMMb ` `  dMMMr..~..~.........~..~..~..(gMMb ` ` ` ` ` ` ` ` ` ` ` ` ` ` ` `.(+gMMMMMMMM#~            //
//                 .dMMMMNNNNm...` ` ` ` ` ` ` ` ` ``  ?WMMNo--_...........~..~......dMMMD` `` ?WM#>..~..dMMMb` ` ` dMMMr..........~.........-(qNMMMC`` ` ` ` ` ` ` ` ` ` ` ` ` `  ..(NMMMMMMM#7WM#-            //
//                .MMMMMMMMMMMMMmJJ.` ` ` ` ` ` ` `  `` `?WMMMNa+....~..~............dMMm, ` `  dM#>.....dMM#= ` `  ?MMMr......~.....~...~(J+dMM#Y5``  ` ` ` ` ` ` ` ` ` ` ` `  .JJMMMMMMMMMMM#<dMMN}           //
//                .MMMMMMMMMMMMMMMNm+..  ` ` ` ` ` ` ` `   ?HMMMMNNNNs----------_.~..dMMMb` ` ` dM#>_....dMM}` ` `` `jMMNs.~.....~..--(gNNNMMMM=`  ` ` ` ` ` ` ` ` ` ` ` ` ..([email protected]~dMMN}           //
//               .-MMMMMMMMMHMMMMMMMMMN&-.` ` ` ` ` ` ` `` `  .THMMMMMMMMMMMMMMNmJJJJdMMM3`  `  dMMNr..~.dMM} ` `  ` jMMMNJJJJJJJJJJdMMMMMHB>  ` `  ` ` ` ` ` ` ` ` ` ` .--MMMMMMMHBC..MMMMMMK ` JMN}           //
//               (MMMMMMMMNm;(77MMMMMMMMMNe-   ` ` ` ` ` ``  `  `_777UMMMMMMMMMMMM#YMB77! `` `  dMMMr.._uN#=!` ` `` `_7MMMMMMMMMMMMMMB777! ` `  ` `` ` ` ` ` ` ` ``  (ggMMMMMM#Y7!.`...MMMMMMb  `jMMl           //
//               (MMMMMMMMMMr...__(MMMMMMMMNNm.. ` ` `  `  `` ` ` ` ` ``````````````  ` `  `` `` zMMr.._dM#!` ` `  ` ` -dMMMMMMMMY``` ` ` ` ` ` ` ` ` ` ` ` ` ` ...NNMMMMMMMC__..``.`..MMMMMMb`  jMMMR          //
//              (gMM}jMMMMMMr.`.... ?TTMMMMMMMNag+` ` `` ` ` ` ` ` ` `` `` `` `` ``` ` ` `  ` `  jMMHx(gMM#~`  ` `` `   `  ` `` ```` ` ` ` ` ` ` ` ` ` ` ` ``(ggMMMMMMMHHMNm/..`..`..`.MMMMM9^`` jMMMb          //
//              dMMM}jMMMMMMr`.``.`.`..(WMMMMMMMMNN... ` ``  ` ` ` `  `  ` ` ` ` `  ` ` `` ` ` `` (MMK(MMD`  `` `  ` `` `` `  `   ` ` ` ` ` ` ` ` ` ` ` `...dMMMMMMM800wrXMMr.`.`..`.`.MMMMM}  ``jMMMb          //
//              dMMM}(TMMMMMr.`..`.`.`.MMMMUWMMMMMMMMN+J- ` ` ` ` ` `` `` ` ` ` ` ` ` `  `` ` `  `.TMNgMB= ` ` ` `` ` `  ` `` `` ` ` ` ` ` ` ` ` ` ` `.(+dMMMMMMM8rrrrtrtXMMr.`.``.`...MMM#!``   jMMMb          //
//              dMMM}`.MMMMMr..`.`..`+NMMNvvOC<?WMMMMMMMNNm-.. ` ` `  `  ` ` ` ` ` ` ` `  ` ` ` `   dMMM}` `  ` `  ` ` `` `  ` ` ` ` ` ` ` ` ` `  ..dNNMMMMM8UUwrrtrtrrtrXMMr`...`..``[email protected]~` `` -?MMb          //
//              dM#!` .TMMMMm.`.`.`..JMMKvvO<     .MMMMMMMMMMNJJ.` ` ` `` ` ` ` ` ` ` `` ` ` ` ` ```````  ` `` ` `` ` `  ` ` `  ` ` ` ` ` ` ` .(JdMMMM#BYY1OrtrtrtrtrtrrtXMMr``      (JMMR``  ` ` .MMb`         //
//            .qMM#~` ` dMMMMK. .`.``JMMKvvrO+-...(MMMMMMMMMMMMMNgm-  `  ` ` ` ` ` ` `  ` ` ` ` `  `   ` `` ` ` `  ` ` `` ` ` `` ` ` ` ` ` ..(gMMMMMY?!  ` ztrrtrrtrrtrwWMMM}        jMMMD ` ` ` `.MMb.         //
//            .MMM#~`` ` JMMMM8!`.`..JMMKvvvvvvvrZOMMMMMHzXMMMMMMMMNe...` ` ` ` ` ` ` `` ` ` ` ` `  ` ` `  ` ` ` ` ` `  ` ` ` ` ` ` ` ` ...MMMMMMHrO+-...(+?<?1OrtrrtrwQMM#!        dMMM2  `` ` ` .MMM#~        //
//            .MMM#~ `  `_7MMNe_`    JMMNkvrvvvO<~.MMMMMKvvwWWHMMMMMMMNagx  `  ` ` ` ` ` ` ` ` `` `` ` ` `` ` ` ` ` ` `` ` ` ` ` ` `  .gMMMMMMMMRrrtrrrrrt>   .ztrtrrqNMMB=`      .gMM#=! `  ` `` .MMM#~        //
//            .MMME~` ` ` .HMMMN{     (MMNmwrvrw+-.(dMMMKvvrvvvXXWMMMMMMMMNNe. ` ` ` `  ` ` ` `  ` ` ` ` ` ` ` ` ` ` `  ` ` ` ` `  [email protected]!~vMMMNAAwrtrtrOzzzOrrtwQMMMM=       .+MMMME~ `` ` `  `.MMM#~        //
//           `.MMb` ` `` `  dMMMm+     7MMMNkvvvvvvvvUHHSvvvrvvvrvwQMMMMMMMMMNgg, ` ` `` ` ` ` `` ` ` ` ` ` ` ` ` ` ` `` ` ` ` ``(gMM#TT!.`.`..7MMMMNmmwrrrrrrwQmmNMM#=`      .jMMMM9^ ` ` ` ` `` .7MMNm-       //
//            .MMb ` `  ` ` _?MMMNR..    ?MMMNNkAyvvvvvvvvrvvrvvwXMMM#!!!vMMMMMMNy ` ` ` ` ` `  ` ` ` ` `  ` ` ` ` ` `  ` ` ` ` dMMMk_`..`.`.`. [email protected]!~`     [email protected]!`` `` ` ` ` ` ` dMMN}       //
//           .JMMb` ` ` `  `  .TMMMMm,    .TYHMMMNmmmmmXvvvrvXmQMMMMB=.`.`...JMMMb` ` ` ` ` ` .(JJJJJJJJJJJ.` ` ` ` ` `` ` ` `  ?HMMMN+J-`..`        (YYYYYYYYY`          .Mmd#9! ``  `  ` ` ` ` `  ?HMMm,      //
//           (MMMb` ` `` `` ` ` _vMMMNm-     -??WMMMMMMNNNNNNMMMM8??~.`.`...qNMM3!` ` ...(NNNNNMMMMMMMMMMMNNNNNNNs....` ` ` ` ` `-?MMMMMNNm-..                      ....gNNMM8!  ` `` ` ` ` ` ` ` `` jMMMb      //
//           (MM#= ` `  `  ` `  ``.TMMMNm,         -7YYYYYYYYY9`    ``` (dMMMM5`` .((dMMMMYYYYYYY=```?YYYYYYYYWMMMMMMN(((, ` ` `  ```?YWMMMMMNJ(((,.           .((((dMMMMM5``` `  `  ` ` ` ` ` ` ` `` .TMN,.    //
//          jNMM}` ` ` ` `` ` `  `  ?TMMMNgm+                      ` (ggMMMMY!  .(gMMMM=<! `  `  `   `   `  `  ?<<?MMMMMMNgm+..  `   `  ?<?MMMMMMMNNgggggggggggMMMMMMB<<<!  ` ` `` `` ` ` ` ` ` `  ` ([email protected]~    //
//         .dM#:` ` ` ` ` ` `` `` `     7MMMMMN+...           ` ....dMMMMMB!`..MMMMB>  `  ` `` ` `` ` `` ` ` `` ` `   .TMMMMMMN+. ``  `  ``  ?MMMMMMMMMMMMMMMMMMM$     ` ` ` ` `  `  ` ` ` ` ` ` ...dMMMM$      //
//        .MMB=`  ` ` ` `  `  `  ` ``  ` _77MMMMMMNaggggggggggggMMMMMB77!`` (gMMY!``  ` ` `  ` `  `` `  ` ` ` ` `` ` ` ``_77MMMMNge_`` `  ` ` `` `  ?7777777!`  ` ` ` ` ` ` ` ` `` `` ` ` ` ` ` (gMMMM#=!       //
//      .JMM=`` `` ` ` ` `` `` `` ` ` ` ` `` ``_TMMMMMMMMMMMMMMMMME!```  ..MM9``  ` `` ` ` `` ` `  ` ` ` ` ` ` `  ` ` `  ` ` ?MMMMMNe.`` ` ` `  ` ` ` ` ` ` ` `` ` ` ` ` ` ` ` `  `  ` ` ` ` `  dMMMMMN+..      //
//      dNgggggggggg-` ` ` `  `  ` ` ` ` `  `  ` ` `  ` ` ` `  `  ` ``  (g#Y!`  `  `  ` ` `` ` `` ` ` ` ` ` ` ` ` ` ` ` ` ` ` ` ?WMMMNx.` ` ` `` ` ` ` ` ` `  ` ` ` ` ` ` ` ` ` `` `` ` ` ` ` ` `("TMMMMMN&.    //
//       ?MMMMMMMMMM} ` ` ` `` `` ` ` ` ` ` `` `` ` `` ` ` ` `` `` ` `.dM9~  ` ` `` ``  ...dNm................ ......` ` ` ` ` `  ?MMMMNo. ` `  ` ` ` ` ` ` `` ` ` ` ` ` ` ` ` `  `  ` ` ` ` ` `  ` _~?MMM#~    //
//          dMMMMMMM}` ` ` `  `  ` ` ` ` ` ` `  ` `  ` `  ` `  `  ` `.JY! ` ` ` ` `  `  dMMMMMMMMMMMMMMMMMMMMNJMMMMMm, ` ` ` ` `` ` ?HMMMNJ.` `` ` ` ` ` ` `  ` ` ` ` ` ` ` ` ` `` `` ` ` ` ` ` ``  (JJMMMY`    //
//        .qMMMMM8??`` ` ` ` ` `` ` ` ` ` ` ` `` ` `` ` `` ` `` `` ` -!  ` ` ` ` ` `` ` dMM8V7<<<<??4UUUUUUUUUUUUUWMMb` ` ` ` `  ` ``-?MMM#-  ` ` ` ` ` ` ` `` ` ` ` ` ` ` ` ` `  `  ` ` ` ` ` `  .qMMMMY`      //
//       (MMMMMMr` `` ` ` ` ` `  ` ` ` ` ` ` `  ` `  ` `  ` `  `  ` `  `` ` ` ` ` `  `.(dMNk>~....._jwzuuzuuzuuuzXdMMb ` ` ` ` ` `  ` ` dMMNm. ` ` ` ` ` ` `  ` ` ` ` ` ` ` ` ` `` `` ` ` ` ` .((dMBY=          //
//       -?MMMMMNgm-     ` ` ` `` ` ` ` ` ` ` `` ` `` ` `` ` `` `` ` `  `  ` ` ` ` `` .MMMNRwz-___(+wuuuzuuzuuzuXWMMY! ` ` ` ` `` `  `  ?TMMMb   ` ` ` ` ` `` ` ` ` ` ` ` ` ` ` ` `  ` ` ` ` ` ?MM#_            //
//           ?MMMMMMMM8~` ` ` `  ` ` ` ` ` ` `  ` `  ` `  ` `  `  ` `` ` `` ` ` ` ` `   dMMMHuzzuzuuuuzuuuzuuXQQMMMB> ` ` ` ` `  ``` `  ` .MMM#~` ` ` ` ` `  ` ` ` ` ` ` ` ` ` ` ` `` ` ` ` ` ` 7MMMMm...       //
//            .jggMM9!` ` ` ` `` ` ` ` ` ` ` ` ` ` ` ` ` ` ` `` ``  ` ` ` ` ` ` `  ` `  ?WMMNNNkuuuuuzuuuuuXWMMMMB=``` ` ` ` ` `  ` ` `  ` ?MMNm- ` ` ` ` ` ` ` ` ` ` ` ` ` ` ` ` `  ` ` ` ` ` ` ` ?MMMN}       //
//          .([email protected]! ` ` ` ` `  ` ` ` ` ` ` ` ` ` ` ` ` ` ` `  ` ` ` ` ` ` ` ` ` `` ` ` ` (MMMMMMMNkQQQQMMMMMMMM=``  ` ` ` ` ` ``  ` `` `   dMMM}` ` ` ` ` ` ` ` ` ` ` ` ` ` ` ` ` `` ` ` ` ` ` ...NMMMM>       //
//        .(MMMMMN&&&&&&&&&. ` ` ` ` ` ` ` ` ` ` ` ` ` ` ` ` `` ` `` ` ` ` ` ` ` ` ` ` `    ?""TMMMMMMMMMM#Y""=`` ``  ` ` ` ` ` `` `  `` `` ?WMMm,` ` ` ` ` ` ` ` ` ` ` ` ` ` ` ` `  ``` `` (&&&MMMMM#=`        //
//        .MMMMMMMMMMMMMMMMN{ `` ` ` ` ` ` ` ` ` ` ` ` `` ` `  ` `.q{ ` ` ` ` ` ` ` ` ` `` ` `  _!!!!!!!!!!  `` `  `` `` ` ` `  ` ` `  ` ` ` jMMMb ` ` ` ` ` ` ` ` ` ` ` ` ` ` ` `  [email protected]!~`          //
//          ?YYYYYYYYYYY!jMMm,  ` ` ` ` ` ` ` ` ` ` ` `  ` ` ``  `.H}` ` ` ` ` ` ` ` ` ` `` ` ` `` `` ```  `  `` `  `  `  ` ` `` ` `` ` ` ` `jMMMb` ` ` ` ` ` ` ` ` ` ` ` ` ` ` `.JJdMMMMMMMBYYY!               //
//                        ?MMNm-..` ` ` ` ` ` ` ` ` ` ` ` ` ` ` `(NM} ` ` ` ` ` ` ` ` `   ` `  `  `  ` ` `` `  ` `` `` `` ` `  `  `  ` ` ` ` -?MMb.  ` ` ` ` ` ` ` ` ` ` ` `  ..uNMMM8?????!`                   //
//                          ?MMMMm(-.` ` ` ` ` ` ` ` ` ` ` ` ` ` jMM}` ` ` ` ` ` ` ` ` ``  ` `` `` `` `  ` ` `` `  ` `  `` ` `` ``                                                                              //
//                                                                                                                                                                                                              //
//                                                                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract REDH is ERC721Creator {
    constructor() ERC721Creator("Re:donuthouse", "REDH") {}
}