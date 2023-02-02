// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Guttestreker: Special edition cards
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//             .BJ                                                                                                                                              //
//           [email protected]#                              Y^    ~?!:                           .7                                                                          //
//          [email protected]@?                              [email protected]?   ^@@@&:.::::^^^.    ~YPGPP5YJ?7~~&@!..                                                                       //
//        .&@B        ..:~!7?J5PGGGBB########&@@##B#@@@&P5YJJ?7~~^.      .:^[email protected]@@&&&&&&&&#BG5J7~^.                                                         //
//       [email protected]@@5?5G#&&&@@@@&&@@&[email protected]@@?::... [email protected]@!   ^@@@. ..........       .~.     [email protected]@!    ..^~!?YPG#&&&&&#P.       .G~                                          //
//      ^@@@&&&[email protected]@@@@7  [email protected]   [email protected]@#      :@@G    [email protected]@Y [email protected]@@BBBGGP5.   ~GB5!      [email protected]#  :~!!!^.       .:^~!?^..     [email protected]!    .?G.                                  //
//     [email protected]@@.      [email protected]@@@&  ^@@.  ^@@&.      @@&     @@G  [email protected]@7       [email protected]&?        [email protected]@~ [email protected]@@#?5B##5~  .&@@GJJ555Y:  [email protected]@.  7#&@J....          7&#BJ.               //
//     [email protected]@?    ^[email protected]@@@@@~  @@!   &@@:      [email protected]@!    [email protected]&  .&@@7:...   [email protected]@@&BBGGPP! [email protected]@&  :@@@^   [email protected]@&~ [email protected]@          [email protected]@[email protected]&! :#@@@@&&&&&&~   [email protected]@@#BBBGY!:.        //
//    [email protected]@@   ^#@@@@@@@#  [email protected]#   [email protected]@!      [email protected]@#     &@:  [email protected]@#GGGGG:   .:^[email protected]@@@Y. [email protected]@?  ^@@@&#&&##B?. [email protected]@YJJ^    [email protected]@@@G^    [email protected]@7 ......    [email protected]@&   :[email protected]@@@&#G?    //
//    [email protected]@&.~#@@@[email protected]@@^  @@?  [email protected]@7      [email protected]@&.    ^@Y   [email protected]@             [email protected]~    &@@:  [email protected]@@@@@@~     [email protected]@B777.    [email protected]@@@~     #@@!...     :[email protected]@@@&&@@@@@@@@@@&    //
//    &@@@@@@@P:  &@@#   &@#[email protected]@~      [email protected]@@~     5#  :[email protected]@@###&&!    :[email protected]@5.     [email protected]@@   [email protected]@~ :[email protected]@Y   :@@~         [email protected]@~7#&5: :@@@GGG5   .&@@@@@@@@#BG5Y?7!~^:.    //
//    &@@@&P~    [email protected]@@^   [email protected]@@@B.       @@&!      .    ~~~~~^^^:     &&7        !GG7   [email protected]!      !5~ J&@@#GGPP5~  ^@@Y   [email protected]@@B:::.... [email protected]@@@@@@~               //
//    :!:.       #@@&     .~^.        .5~                    ...::^!J!~!7??JJJJJYJ??JJGGJJ????7!~!!~~~^^~^:::.  :7?        [email protected]@@@@@@@@&^  @@@@[email protected]@&7             //
//              [email protected]@@?                      ..^~!?J5PGB#&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&#GPYJ?7!~^:~^:..       ^@@&:  [email protected]@@P:          //
//              [email protected]@&             .:~?5G#&&@@@@@@@@@@@@@@@@@@@@@&&&##BBGPP55YYJJ????????????JJJJYY55PPGGBB##&&&@@@@@@@@@@@@@@@@@@&&#BPYJ7!~~.     [email protected]@@#!        //
//              #@G.     .^!YG#&@@@@@@@@@@@@@&&#BP5J?7~^::..                                                    ...:^~!7JYPGB#&&@@@@@@@@@@@@@@@@&&@@@@@@J       //
//              5~    7#@@@@@@@@@@&&BPY?~^..                                                                                     ..:^~7?YPGB##&&&&&&&&#B?       //
//                   J&&@@&BPJ!^..                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract GSSC is ERC1155Creator {
    constructor() ERC1155Creator("Guttestreker: Special edition cards", "GSSC") {}
}