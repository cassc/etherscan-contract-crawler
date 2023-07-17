// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Headcover DAO - Headcovers
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                      _   _                _                           ____    _    ___                     //
//                     | | | | ___  __ _  __| | ___ _____   _____ _ __  |  _ \  / \  / _ \                    //
//                     | |_| |/ _ \/ _` |/ _` |/ __/ _ \ \ / / _ \ '__| | | | |/ _ \| | | |                   //
//                     |  _  |  __/ (_| | (_| | (_| (_) \ V /  __/ |    | |_| / ___ \ |_| |                   //
//                     |_| |_|\___|\__,_|\__,_|\___\___/ \_/ \___|_|    |____/_/   \_\___/                    //
//                                                                                                            //
//                                                                                                            //
//                                                     ,[email protected]@Ng,                                                //
//                                                 ,@@@@@@@@@@@@p                                             //
//                                              ,@@@@@@@@@@@@@@@@@@g                                          //
//                                            ,@@@@@@@@@@@@@@@@@@@@@@N                                        //
//                                           @@@@@@@@@@@@@@@@@@@@@@@@@@g                                      //
//                                         ,@@@@@@@@@@@@@@@@@@@@@@@@@@@@N                                     //
//                                        ,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@K                                    //
//                                        ]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                    //
//                                        ]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                    //
//                                         ]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                     //
//                                          "@@@@@@@@@@@@@@@@@@@@@@@@@@P                                      //
//                            [email protected]@@@@@Ng       @@@@@@@@@@@@@@@@@@@@@@@@K      [email protected]@@@[email protected]@g,                       //
//                          ]"     "`]@@@     [email protected]@@@@@@@@@@@@@@@@@@@@@@     @@@@``     "k                      //
//                                    "[email protected]@    ]@@@@@@@@@@@@@@@@@@@@@@@    @@@`                                //
//                                     @@@@   @@@@@@@@@@@@@@@@@@@@@@@@p  #@@@                                 //
//                                     ]@@@  ]@@@@@@@@@@@@@@@@@@@@@@@@@  @@@@                                 //
//                                    ]@@@@  [email protected][email protected]@@@@@@@@@@@@@[email protected]` [email protected]@@K                                //
//                                   ,[email protected]@@@ @@`  "*@@@@@@"`"[email protected]@@@N"   ]@ ]@@@@p                               //
//                                   @@@@@  ]@      ]@@@@@@@@@@@`     ]C  [email protected]@@@                               //
//                          [email protected]@@@g   @@@@[    Ng    ]@@@@@@@@@@@    gP    ]@@@@   [email protected]@@@g                      //
//                         ]@   %@K [email protected]@@@@      `"[email protected]@@@@R**[email protected]@@@@P`      @@@@@@ ]@@   ][                     //
//                          RP  @@@  "@@@@@g      ]@@"        "[email protected]@      [email protected]@@@@P  @@@  *P                      //
//                             [email protected]@K   @@@@@@@Bw,,[email protected]@            [email protected]@[email protected]@@@@@@@C  ]@@N,                        //
//                          ,[email protected]@@P     "]@@@@@@@@@@@` ,      ,  ]@@@@@@@@@@B"     "@@@g,                      //
//                         ]@@@@`   ,[email protected]@@@@@@@@@@@@@@,]g* ,*,p,)@@@@@@@@@@@@@@Bg    [email protected]@@K                     //
//                        @@@@@   [email protected]@@@@@@@@@P]@@@@@@NggN,,@[email protected]@@@@@@*[email protected]@@@@@@@@@,  %@@@@r                   //
//                        ]@@@p,[email protected]@@@@@@@@` ,@@@@@@@"  "BRRBC  "%@@@@@@w  %@@@@@@@@@,,@@@@                    //
//                        [email protected]@@@@@@@@@`     @@@@@@@`      @@P      *@@@@@@,     @@@@@@@@@@@                    //
//                         "*@@@@PNP`    ,@@@@@P         @@         "[email protected]@@@K     *N*[email protected]@@P"                     //
//                            `         ]@@@@P                        ]@@@@C         `                        //
//                                      @@@@P                          "@@@@                                  //
//                                      @@@@                            @@@@                                  //
//                                      ]@@@p                          ]@@@C                                  //
//                                       *@@@N                       ,@@@@`                                   //
//                                         "[email protected]@@,                  [email protected]@@P`                                     //
//                                            "[email protected]@               ,@@P`                                        //
//                                              "@@              @@                                           //
//                                               ]@              @P                                           //
//                                              ,@`               %g                                          //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract HDCVRS is ERC721Creator {
    constructor() ERC721Creator("Headcover DAO - Headcovers", "HDCVRS") {}
}