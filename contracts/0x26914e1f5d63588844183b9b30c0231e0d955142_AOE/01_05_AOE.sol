// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ART OF ESSIE
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                               //
//                                                                                                                                                                                                               //
//                                                                                                                                                                                                               //
//                                                                                                                                                                                                               //
//                                                                                                                                                                                                               //
//                   ww ww,www ,w,,ww gww,w,,w,ww~ww    ,@     ,@     ,@     ,@      ,~ yw,www  ww ww ,ww,ww ww wwyww  w, ww,ww  ,w gw~ wwcww ww ww~ww  gy ww,www ,w,,ww yww,w,,w,.wwww  ,~ ,wwwww  ww ww        //
//                  ]**U["m [  [email protected]]^^ @$,@"@m"@,@ @$   [email protected]@@   /@@@,  /@@@,  /@@@w    P*@["% ]  ]@]UP^ ]Q[v,$mC]U],[$, @*]gP"p]P  N,P$^  @$pC][email protected]"@,b]D$ ]P*[email protected]"g @  %[email protected]]P^ $$,m"@m,%,@,@$  @*$]"] ]  ]@][email protected]^        //
//               rwg                                                                                                                                                                                      pgm    //
//               **$                                                                                                                                                                                      $"[    //
//               P"%                                                                                                                                                                                      [email protected]@    //
//              ],K]                                                                                                                                                                                      [email protected]]    //
//               mgN                                                                                                                                                                                      [ ]    //
//               P"$                                                                                                                                                                                      L,]    //
//               [email protected]@                                                                                                                                                                                      L%]    //
//                ,                                                                                                                                                                                       mg,    //
//               *$*                                                                                                                                                                                      wNP    //
//               Qy$                                                                                                                                                                                      "[]    //
//                                                                                                                                                                                                        ` ]    //
//               P**                                                                                                                                                                                        ]    //
//               [email protected]"                                                                                                                                                                                      gPm    //
//               "[email protected]                                                                                                                                                                                      *@*    //
//               [email protected],                                                                                                                                                                                       L]    //
//                ,,                                                                                                                                                                                      wgw    //
//               NNN                                                                                                                                                                                      L*[    //
//               P*$                                                                                                                                                                                      [email protected]]    //
//               [email protected]$                                                                                                                                                                                      PgN    //
//               @gw                                                                                                                                                                                      $`$    //
//               NhP                                                                                                                                                                                      [`]    //
//               [email protected]$                                                                                                                                                                                      L$]    //
//                ,                                                                                                                         ,,gggg,,                                                      ,,     //
//               NNm                           @@@@@@@@@@@@@@@K       ]@@@@@@@@@@@@@@@@@@Ng    ]@@@@@@@@@@@@@@@@@@@@@@@@                ,[email protected]@@@@@@@@@@@Nw        ]@@@@@@@@@@@@@@@@@@@[                     ,@m    //
//               Pw$                          ]@@@@@@P  @@@@@@@       ]@@@@@@@@@@@@@@@@@@@@@@, ]@@@@@@@@@@@@@@@@@@@@@@@@              [email protected]@@@@@@@@@@@@@@@@@b      ]@@@@@@@@@@@@@@@@@@@[                     *@$    //
//                `                           @@@@@@@   ]@@@@@@L      ]@@@@@@@@@@@@@@@@@@@@@@@p]@@@@@@@@@@@@@@@@@@@@@@@@            ,@@@@@@@@@@@@@@@@@@@@@@g    ]@@@@@@@@@@@@@@@@@@@[                     * $    //
//               Nmm                         ]@@@@@@[    @@@@@@@      ]@@@@@@@^^^^^***[email protected]@@@@@@@'^^^^^^^^[email protected]@@@@@P^^^^^^^^           ,@@@@@@@@@*"``""[email protected]@@@@@@@K   ]@@@@@@P^^^^^^^^^^^^^                     ""%    //
//               Pg*                         @@@@@@@     %@@@@@@L     ]@@@@@@[         "@@@@@@@         ]@@@@@@                    @@@@@@@@          ]@@@@@@@p  ]@@@@@@P                                  gmg    //
//               *$$                        ]@@@@@@@      @@@@@@@     ]@@@@@@[          @@@@@@P         ]@@@@@@                   ]@@@@@@@            ]@@@@@@@  ]@@@@@@P                                  [email protected]    //
//               [email protected]                         @@@@@@@       [email protected]@@@@@C    ]@@@@@@[        ,[email protected]@@@@C          ]@@@@@@                   @@@@@@@              @@@@@@@  ]@@@@@@P                                  "P]    //
//                 ,                       ]@@@@@@@,,,,,,,]@@@@@@@    ]@@@@@@@@@@@@@@@@@@N*`            ]@@@@@@                   @@@@@@@              [email protected]@@@@@L ]@@@@@@Ngggggggggggg                      ,,,    //
//               [email protected]@                       @@@@@@@@@@@@@@@@@@@@@@@P   ]@@@@@@@@@@@@@@@@@[               ]@@@@@@                   @@@@@@@              [@@@@@@P ]@@@@@@@@@@@@@@@@@@@                      LN]    //
//               [email protected]                      ]@@@@@@@@@@@@@@@@@@@@@@@@   ]@@@@@@@@@@@@@@@@@@@@@@@,         ]@@@@@@                   @@@@@@@              @@@@@@@  ]@@@@@@@@@@@@@@@@@@@                      [email protected]]    //
//               [email protected]%                      @@@@@@@@@@@@@@@@@@@@@@@@@   ]@@@@@@@[email protected]@@@@@         ]@@@@@@                   ]@@@@@@@            ]@@@@@@@  ]@@@@@@@@@@@@@@@@@@@                      @,w    //
//               $][                      @@@@@@@```````````]@@@@@@@  ]@@@@@@[          ]@@@@@@         ]@@@@@@                    @@@@@@@b          [email protected]@@@@@@C  ]@@@@@@P                                  NCP    //
//               [email protected]                     @@@@@@@P            @@@@@@@  ]@@@@@@[          ]@@@@@@         ]@@@@@@                    ]@@@@@@@@bg,,,,,[email protected]@@@@@@@P   ]@@@@@@P                                  P^$    //
//               P[$                     @@@@@@@             ]@@@@@@@ ]@@@@@@[          ]@@@@@@         ]@@@@@@                     "@@@@@@@@@@@@@@@@@@@@@@P    ]@@@@@@P                                  P$]    //
//                                      ]@@@@@@@              @@@@@@@ ]@@@@@@[          ]@@@@@@         ]@@@@@@                       %@@@@@@@@@@@@@@@@@@@      ]@@@@@@P                                  ,      //
//               [email protected]                    @@@@@@@               [email protected]@@@@@K]@@@@@@[          ]@@@@@@         ]@@@@@@                         "[email protected]@@@@@@@@@@@@*        ]@@@@@@P                                   @]    //
//               M"b                                                                                                                        ""****""                                                      mpm    //
//               "^`                   ggggggggggggggggggggggggg,        ,[email protected]@@@@@@Ngw,                  ,[email protected]@@@@@@Ngg,          ggggggggggggggggggggggg   ggggggggggggggggggggggggg                      M"B    //
//               Wgg                   @@@@@@@@@@@@@@@@@@@@@@@@@[     ,@@@@@@@@@@@@@@@@@@N,           [email protected]@@@@@@@@@@@@@@@@@w       @@@@@@@@@@@@@@@@@@@@@@@   @@@@@@@@@@@@@@@@@@@@@@@@@L                     **$    //
//               N,m                   @@@@@@@@@@@@@@@@@@@@@@@@@[    @@@@@@@@@@@@@@@@@@@@@@@,       /@@@@@@@@@@@@@@@@@@@@@@N     @@@@@@@@@@@@@@@@@@@@@@@   @@@@@@@@@@@@@@@@@@@@@@@@@L                     ,,,    //
//               NNm                   @@@@@@@@@@@@@@@@@@@@@@@@@[   @@@@@@@@@@@@@@@@@@@@@@@@@g     ]@@@@@@@@@@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@@   @@@@@@@@@@@@@@@@@@@@@@@@@L                     k]@    //
//               $$                    @@@@@@@@@@@@@@@@@@@@@@@@@[  ]@@@@@@@@P"`   `"[email protected]@@@@@@@@p    @@@@@@@@@*`    `*[email protected]@@@@@@@@   @@@@@@@@@@@@@@@@@@@@@@@   @@@@@@@@@@@@@@@@@@@@@@@@@L                     ^P$    //
//                 `                   @@@@@@@@P                   @@@@@@@@[          [email protected]@@@@@@@   ]@@@@@@@@          ]@@@@@@@@C         [@@@@@@@P          @@@@@@@@                                              //
//               [email protected]$                   @@@@@@@@P                   [email protected]@@@@@@@,         ]@@@@@@@@    @@@@@@@@b          [email protected]@@@@@@K         [@@@@@@@P          @@@@@@@@                                       [$]    //
//               [email protected]                   @@@@@@@@P                   ]@@@@@@@@@@@gg,                 @@@@@@@@@@@Ngg,                      [@@@@@@@P          @@@@@@@@                                       [email protected]]    //
//               mgm                   @@@@@@@@@@@@@@@@@@@@@@@      [email protected]@@@@@@@@@@@@@@@@gg,          ]@@@@@@@@@@@@@@@@@Nw,,               [@@@@@@@P          @@@@@@@@@@@@@@@@@@@@@@@                        $,[    //
//               MQP                   @@@@@@@@@@@@@@@@@@@@@@@       %@@@@@@@@@@@@@@@@@@@@@b,       "[email protected]@@@@@@@@@@@@@@@@@@@@w            [@@@@@@@P          @@@@@@@@@@@@@@@@@@@@@@@                        [email protected]    //
//               UP]                   @@@@@@@@@@@@@@@@@@@@@@@         "[email protected]@@@@@@@@@@@@@@@@@@@@,       '[email protected]@@@@@@@@@@@@@@@@@@@b          [@@@@@@@P          @@@@@@@@@@@@@@@@@@@@@@@                        NN$    //
//               Pp%                   @@@@@@@@@@@@@@@@@@@@@@@             `*[email protected]@@@@@@@@@@@@@@@g           "*[email protected]@@@@@@@@@@@@@@@@         [@@@@@@@P          @@@@@@@@@@@@@@@@@@@@@@@                        [email protected]$    //
//               """                   @@@@@@@@P                  NNNNNNNN       `"*[email protected]@@@@@@@@@@ #NNNNNNNN       "*[email protected]@@@@@@@@@K        [@@@@@@@P          @@@@@@@@                                       ` `    //
//               C$,                   @@@@@@@@P                  @@@@@@@@C            ]@@@@@@@@P]@@@@@@@@            '[email protected]@@@@@@@        [@@@@@@@P          @@@@@@@@                                       `P$    //
//               @Pm                   @@@@@@@@P                  [email protected]@@@@@@@             @@@@@@@@P]@@@@@@@@g            ]@@@@@@@@        [@@@@@@@P          @@@@@@@@                                       @gg    //
//               *M"                   @@@@@@@@Wwwwwwwwwwwwwwwwww ]@@@@@@@@@w,        ,@@@@@@@@@  [email protected]@@@@@@@@,         [email protected]@@@@@@@@ [email protected]@@@@@@@@ggggggg   @@@@@@@@wwwwwwwwwwwwwwwww                      [email protected]    //
//               U,,                   @@@@@@@@@@@@@@@@@@@@@@@@@[  ]@@@@@@@@@@@@@@@@@@@@@@@@@@@K   @@@@@@@@@@@@@@@@@@@@@@@@@@@@  @@@@@@@@@@@@@@@@@@@@@@@   @@@@@@@@@@@@@@@@@@@@@@@@@L                     [email protected]    //
//               g,g                   @@@@@@@@@@@@@@@@@@@@@@@@@[   *@@@@@@@@@@@@@@@@@@@@@@@@@P     %@@@@@@@@@@@@@@@@@@@@@@@@@`  @@@@@@@@@@@@@@@@@@@@@@@   @@@@@@@@@@@@@@@@@@@@@@@@@L                      ,     //
//               [email protected]                   @@@@@@@@@@@@@@@@@@@@@@@@@[     *@@@@@@@@@@@@@@@@@@@@@@`       "%@@@@@@@@@@@@@@@@@@@@@P    @@@@@@@@@@@@@@@@@@@@@@@   @@@@@@@@@@@@@@@@@@@@@@@@@L                     C\]    //
//               *$`                   BBBBBBBBBBBBBBBBBBBBBBBBBK        "[email protected]@@@@@@@@@@@NP"             "*[email protected]@@@@@@@@@@@@N*`      BBBBBBBBBBBBBBBBBBBBBBN   BBBBBBBBBBBBBBBBBBBBBBBBBL                     MNN    //
//                ""                                                                                                                                                                                       `'    //
//               P[$                                                                                                                                                                                      P$]    //
//               p,g                                                                                                                                                                                      @gN    //
//               ,,[                                                                                                                                                                                      9"[    //
//               [email protected]                                                                                ]@"]@/@"[email protected] @""@[email protected]""@                                                                                  [email protected]]    //
//               CK]                                                                                ]NM" ]NP,@UNN*`JNM*`                                                                                  @[email protected]    //
//               C{g                                                                                `````  "`  ```` ````                                                                                  pgm    //
//               ***                                                                                                                                                                                      `"^    //
//               P$                                                                                                                                                                                       "PN    //
//               gm,                                                                                                                                                                                      $$,    //
//               [email protected]                                                                                                                                                                                      ,[email protected]    //
//               r                                                                                                                                                                                        [email protected]    //
//               C ,                                                                                                                                                                                        '    //
//               [email protected],                                                                                                                                                                                             //
//                                                                                                                                                                                                               //
//                                                                                                                                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract AOE is ERC721Creator {
    constructor() ERC721Creator("ART OF ESSIE", "AOE") {}
}