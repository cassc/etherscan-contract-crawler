// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Goliath
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////
//                                                                             //
//                                                                             //
//                                          ________                           //
//                        ._______        [email protected][email protected]_                    //
//                     [email protected][email protected]@[email protected]@@[       `@@[email protected]@L                  //
//                [email protected]@@@~       [email protected]~~    `~~        `~     [email protected],                //
//              ][email protected]@[email protected]~       ..""                         `@@@@z_            //
//            [email protected]=  [email protected]'                                      ]@ `[email protected]          //
//           [email protected]'  _"                                              [email protected]         //
//         [email protected]                                                   _,`@[        //
//        [email protected]@P                                                  `[email protected][        //
//       [email protected]]@                                                     `@@L_       //
//       [email protected]"`~                                                      ]@@@L      //
//      [email protected]'                                                         ]@`@@,     //
//     )@P                                                             ]@[,    //
//     [email protected]                                                              ]@['    //
//     @[                                                           ez ]@'     //
//     @[                                                    _,     ]@[email protected]'      //
//     @[                                                   ]@[     ]@~        //
//     ]@                                __     __          [email protected]'    ]@[         //
//    ]@~                                ]@     a[   z    [email protected]'    ]@@'         //
//    ]@                                 ]@   [email protected]'  [email protected]  [email protected]'  [email protected]~           //
//    ]@                                [email protected]' [email protected][email protected]@[email protected]@@@@@@@~'            //
//    ]@_                           [email protected]@@@@@@@@@@-~~~~~~   [email protected]                //
//    `@@z                         [email protected]"                      [email protected]              //
//      ]@[                       [email protected]~                         `@@_             //
//      a[                       [email protected]'                           `@@,            //
//      @[                      [email protected]'                             "@L            //
//      @[                      @P                               [email protected]            //
//      [email protected]                     @[                               `@L           //
//       [email protected],                   @[                                @[           //
//        `@L                   @[                                @[           //
//         @[                   @L      ____                      ]@           //
//         ]@                   [email protected],    [email protected][email protected]@__                   ]@           //
//         `@L                   @L        `[email protected]@@z                 ]@           //
//          `@b_                 ]@,           ]@bz_              ]@[email protected]       //
//           `]@,                 @b            "[email protected]@___        _ ]@@~~'       //
//            ]@[                 @[               `[email protected]     [email protected]@@@[          //
//            ]@[          _zzz, e][                   [email protected]@,   ]@' [email protected]           //
//            ]@[         )@[email protected] [][              [email protected]@@@zz_    " [email protected]          //
//            `@@         ]@  `@@@@[              ]@L   '@bL .za'[email protected]@          //
//             `@L        ]@ @ `@@~,               [email protected] # `]@c]@ # [email protected]@          //
//              ]@z       [email protected] ], ``                  `[email protected]@[email protected][]@[email protected]~           //
//               [email protected]      ]@L  ez                            `]@]@L            //
//                `@z     ]@[email protected]@[                             `@[email protected][            //
//                 `@b,   ]@'"~~                      ._zzzzz, `@@zzz,         //
//                  `@@   [email protected]                          ]@~ _   z `@] ]@         //
//                   ]@  )@P        )[email protected]@@@,           ]L  @@,  ' `[email protected]@         //
//                   `@[email protected]'        ]@  _='           `[email protected]___=_    [email protected]@L       //
//                    `@[email protected]'         ]@ `@@bz___          "~    @@[email protected]@z_a[       //
//                     `@@              `@@@@[email protected]___     ][  ~~~"       //
//                      ]@,              `[email protected]@[email protected]_]@' [email protected]@[email protected]@[email protected]             //
//                      `@[                   [email protected]@@@@@[email protected]@@'             //
//                       ]@                               "[email protected]@@@@@@b          //
//                       ]@,                                     [email protected]          //
//                       ]@L                                    ]@@"           //
//                       `@[                                    ]@[            //
//                       )@[                [email protected]@@@@@@zzz_,     ]@[            //
//                       ]@[              [email protected]~~'      `[email protected]@[email protected]~             //
//                       ]@[             [email protected]'                                  //
//                       `~[             `~'                                   //
//                                                                             //
//                                                                             //
/////////////////////////////////////////////////////////////////////////////////


contract G1 is ERC721Creator {
    constructor() ERC721Creator("Goliath", "G1") {}
}