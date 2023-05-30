// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BekaRiosArt Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                         //
//                                                                                         //
//                                                                                         //
//         '                                                                         _     //
//                                        ,,gwgggggggwwg,,                                 //
//                                 ,[email protected]@@@@@@[email protected]@@@@@@@Nw,                        //
//                             ,[email protected]@@@@@NM%""'````   ```'""%%%[email protected]@@@@Ng                      //
//                          [email protected]@@@@BT"`                        `'[email protected]@@@@w                   //
//                       ,@@@@@M"                                  '*[email protected]@@@w                //
//                     [email protected]@@@M'                                        `[email protected]@@N              //
//                   [email protected]@@@P`                      ,,                     "[email protected]@@N            //
//                 ,@@@@P                      [email protected]*@P%@@,                   "[email protected]@@w          //
//                [email protected]@@K_              ,gg,    ,@@B "  %@@                    [email protected]@@@         //
//               [email protected]@@P4_            ,@@@]@@g  '[email protected]@     *@@_                   |[email protected]@@        //
//              [email protected]@@L               [email protected] P" @@@ ;]@@@N,   ]@@_                   '%@@@       //
//             ]@@@L                [email protected]   ]@@@@@P" `"@w  %@@                    '[email protected]@@      //
//             @@@P                 '[email protected]    "@@@@     ]K   @@L                    ]@@@K     //
//            @@@@_                  ]@@,     "[email protected],       [email protected]                     ]@@@     //
//            @@@P                    "@@w        `       [email protected]                     "@@@C    //
//           ]@@@L                     '@@g           ,,  [email protected]                      [email protected]@@    //
//           ]@@@_                       [email protected]@  `       ,,,[email protected]@_                      ]@@@    //
//           ]@@@_                        ]@@"*""        [email protected]@                       ]@@@    //
//           ]@@@L                         ]@@NN_      NP"@@p                      ]@@@    //
//            @@@L                         ]@@NN   g    gN"[email protected]@,                    @@@P    //
//            [email protected]@@_                        [email protected]@,             "@@g                  ]@@@_    //
//            ]@@@p                        @@@      gggg      %@@                [email protected]@@K     //
//             ]@@@L                     ,@@@_      [email protected]@@@N     [email protected]               @@@@_     //
//              %@@@,                ,[email protected]@@@@P      ]@@@@@@_    ]@L              [email protected]@@_      //
//               [email protected]@@p             [email protected]@@BP`  @    ,@PMMP" ]P    @@`            ,@@@@_       //
//                ]@@@@           [email protected]@          [email protected]           [email protected]@`            [email protected]@@@_        //
//                 "@@@@g          %@      ,[email protected]@@pwg,,,[email protected]@@M"            [email protected]@@@P          //
//                   %@@@@L         "MBBBBRM*""""**%%**""'`              ,@@@@@            //
//                     %@@@@g                                          ;@@@@@`             //
//                       *[email protected]@@@g,                                  ,,@@@@@P                //
//                         `%@@@@@@g,                          ,,[email protected]@@@@N"                  //
//                             *[email protected]@@@@@@g,,,             ,,[email protected]@@@@@@@P`                     //
//                                 "[email protected]@@@@@@@[email protected]@@@@@@@@M"`                         //
//                                       ""*MRNBBBBBBNRP*""`                               //
//                                                                                         //
//                                                                                         //
//                                                                                         //
//                                                                                         //
//                                                                                         //
//                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////


contract BRArtE is ERC1155Creator {
    constructor() ERC1155Creator("BekaRiosArt Editions", "BRArtE") {}
}