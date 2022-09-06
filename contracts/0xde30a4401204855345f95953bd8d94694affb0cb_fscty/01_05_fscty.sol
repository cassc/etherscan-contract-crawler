// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: (f)society
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////
//                                                                                      //
//                                                                                      //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XX                                                                          XX    //
//    XX   MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM   XX    //
//    XX   MMMMMMMMMMMMMMMMMMMMMssssssssssssssssssssssssssMMMMMMMMMMMMMMMMMMMMM   XX    //
//    XX   MMMMMMMMMMMMMMMMss'''                          '''ssMMMMMMMMMMMMMMMM   XX    //
//    XX   MMMMMMMMMMMMyy''                                    ''yyMMMMMMMMMMMM   XX    //
//    XX   MMMMMMMMyy''                                            ''yyMMMMMMMM   XX    //
//    XX   MMMMMy''                                                    ''yMMMMM   XX    //
//    XX   MMMy'                                                          'yMMM   XX    //
//    XX   Mh'                                                              'hM   XX    //
//    XX   -                                                                  -   XX    //
//    XX                                                                          XX    //
//    XX   ::                                                                ::   XX    //
//    XX   MMhh.        ..hhhhhh..                      ..hhhhhh..        .hhMM   XX    //
//    XX   MMMMMh   ..hhMMMMMMMMMMhh.                .hhMMMMMMMMMMhh..   hMMMMM   XX    //
//    XX   ---MMM .hMMMMdd:::dMMMMMMMhh..        ..hhMMMMMMMd:::ddMMMMh. MMM---   XX    //
//    XX   MMMMMM MMmm''      'mmMMMMMMMMyy.  .yyMMMMMMMMmm'      ''mmMM MMMMMM   XX    //
//    XX   ---mMM ''             'mmMMMMMMMM  MMMMMMMMmm'             '' MMm---   XX    //
//    XX   yyyym'    .              'mMMMMm'  'mMMMMm'              .    'myyyy   XX    //
//    XX   mm''    .y'     ..yyyyy..  ''''      ''''  ..yyyyy..     'y.    ''mm   XX    //
//    XX           MN    .sMMMMMMMMMss.   .    .   .ssMMMMMMMMMs.    NM           XX    //
//    XX           N`    MMMMMMMMMMMMMN   M    M   NMMMMMMMMMMMMM    `N           XX    //
//    XX            +  .sMNNNNNMMMMMN+   `N    N`   +NMMMMMNNNNNMs.  +            XX    //
//    XX              o+++     ++++Mo    M      M    oM++++     +++o              XX    //
//    XX                                oo      oo                                XX    //
//    XX           oM                 oo          oo                 Mo           XX    //
//    XX         oMMo                M              M                oMMo         XX    //
//    XX       +MMMM                 s              s                 MMMM+       XX    //
//    XX      +MMMMM+            +++NNNN+        +NNNN+++            +MMMMM+      XX    //
//    XX     +MMMMMMM+       ++NNMMMMMMMMN+    +NMMMMMMMMNN++       +MMMMMMM+     XX    //
//    XX     MMMMMMMMMNN+++NNMMMMMMMMMMMMMMNNNNMMMMMMMMMMMMMMNN+++NNMMMMMMMMM     XX    //
//    XX     yMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMy     XX    //
//    XX   m  yMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMy  m   XX    //
//    XX   MMm yMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMy mMM   XX    //
//    XX   MMMm .yyMMMMMMMMMMMMMMMM     MMMMMMMMMM     MMMMMMMMMMMMMMMMyy. mMMM   XX    //
//    XX   MMMMd   ''''hhhhh       odddo          obbbo        hhhh''''   dMMMM   XX    //
//    XX   MMMMMd             'hMMMMMMMMMMddddddMMMMMMMMMMh'             dMMMMM   XX    //
//    XX   MMMMMMd              'hMMMMMMMMMMMMMMMMMMMMMMh'              dMMMMMM   XX    //
//    XX   MMMMMMM-               ''ddMMMMMMMMMMMMMMdd''               -MMMMMMM   XX    //
//    XX   MMMMMMMM                   '::dddddddd::'                   MMMMMMMM   XX    //
//    XX   MMMMMMMM-                                                  -MMMMMMMM   XX    //
//    XX   MMMMMMMMM                                                  MMMMMMMMM   XX    //
//    XX   MMMMMMMMMy                                                yMMMMMMMMM   XX    //
//    XX   MMMMMMMMMMy.                                            .yMMMMMMMMMM   XX    //
//    XX   MMMMMMMMMMMMy.                                        .yMMMMMMMMMMMM   XX    //
//    XX   MMMMMMMMMMMMMMy.                                    .yMMMMMMMMMMMMMM   XX    //
//    XX   MMMMMMMMMMMMMMMMs.                                .sMMMMMMMMMMMMMMMM   XX    //
//    XX   MMMMMMMMMMMMMMMMMMss.           ....           .ssMMMMMMMMMMMMMMMMMM   XX    //
//    XX   MMMMMMMMMMMMMMMMMMMMNo         oNNNNo         oNMMMMMMMMMMMMMMMMMMMM   XX    //
//    XX                                                                          XX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//                                                                                      //
//        .o88o.                               o8o                .                     //
//        888 `"                               `"'              .o8                     //
//       o888oo   .oooo.o  .ooooo.   .ooooo.  oooo   .ooooo.  .o888oo oooo    ooo       //
//        888    d88(  "8 d88' `88b d88' `"Y8 `888  d88' `88b   888    `88.  .8'        //
//        888    `"Y88b.  888   888 888        888  888ooo888   888     `88..8'         //
//        888    o.  )88b 888   888 888   .o8  888  888    .o   888 .    `888'          //
//       o888o   8""888P' `Y8bod8P' `Y8bod8P' o888o `Y8bod8P'   "888"      d8'          //
//                                                                    .o...P'           //
//                                                                    `XER0'            //
//                                                                                      //
//                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////


contract fscty is ERC721Creator {
    constructor() ERC721Creator("(f)society", "fscty") {}
}