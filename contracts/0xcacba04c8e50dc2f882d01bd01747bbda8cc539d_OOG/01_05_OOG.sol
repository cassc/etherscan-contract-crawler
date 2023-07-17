// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Out of Gas, Out of Time
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                   ^77777777777777777777777777777777777777777~.                                             //
//                 ^[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#7        .^^:.                               //
//                 [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&.     .J#@@&BY~.                            //
//                 [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&:     [email protected]@@@@@@@#5!:                         //
//                 [email protected]@@@@@@@#Y??????????????????????????P&@@@@@@@&:     ^[email protected]@@@@@@@@@&P?:                      //
//                 [email protected]@@@@@@B.                            [email protected]@@@@@@&:       [email protected]@@@@@@@@@&GJ^                   //
//                 [email protected]@@@@@@P                             :&@@@@@@&:          ^JG&@@@@@@@@@@BY~.               //
//                 [email protected]@@@@@@P                             :&@@@@@@&:             :[email protected]@@@@@@@@@@@#5!.            //
//                 [email protected]@@@@@@P                             :&@@@@@@&:              :&@@@@@@@@@@@@@@7            //
//                 [email protected]@@@@@@P                             :&@@@@@@&.               [email protected]@@@@@@@@@@@@@?            //
//                 [email protected]@@@@@@P                             :&@@@@@@@GGGGGGPY?~:     [email protected]@@@@@@@@@@@@?            //
//                 [email protected]@@@@@@P                             :&@@@@@@@@@@@@@@@@@&P7.   .J&@@@@@@@@@@@?            //
//                 [email protected]@@@@@@P                             :&@@@@@@@@@@@@@@@@@@@@B~    :?G&@@@@@@@@?            //
//                 [email protected]@@@@@@P                             :&@@@@@@@#BBBB#&@@@@@@@@!      [email protected]@@@@@@?            //
//                 [email protected]@@@@@@&7.                         .:[email protected]@@@@@@&:    .:J&@@@@@@#:      [email protected]@@@@@@?            //
//                 [email protected]@@@@@@@@&BBBBBBBBBBBBBBBBBBBBBBBBBB&@@@@@@@@&:       [email protected]@@@@@@7      [email protected]@@@@@@?            //
//                 [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&:       [email protected]@@@@@@J      [email protected]@@@@@@?            //
//                 [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&:       [email protected]@@@@@@J      [email protected]@@@@@@?            //
//                 [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&:       [email protected]@@@@@@J      [email protected]@@@@@@?            //
//                 [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&:       [email protected]@@@@@@J      [email protected]@@@@@@?            //
//                 [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&:       [email protected]@@@@@@J      [email protected]@@@@@@?            //
//                 [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&:       [email protected]@@@@@@J      [email protected]@@@@@@?            //
//                 [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&:       [email protected]@@@@@@J      [email protected]@@@@@@?            //
//                 [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&:       [email protected]@@@@@@J      [email protected]@@@@@@?            //
//                 [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&:       [email protected]@@@@@@J      [email protected]@@@@@@?            //
//                 [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&:       [email protected]@@@@@@?      [email protected]@@@@@@?            //
//                 [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&:       [email protected]@@@@@@?      [email protected]@@@@@@?            //
//                 [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&:       [email protected]@@@@@@?      [email protected]@@@@@@?            //
//                 [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&:       [email protected]@@@@@@?      [email protected]@@@@@@?            //
//                 [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&:       [email protected]@@@@@@?      [email protected]@@@@@@?            //
//                 [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&:       [email protected]@@@@@@?      [email protected]@@@@@@?            //
//                 [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&.       [email protected]@@@@@@?      [email protected]@@@@@@?            //
//                 [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&^       [email protected]@@@@@@?      [email protected]@@@@@@?            //
//            :[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#Y7!^   [email protected]@@@@@@Y      [email protected]@@@@@@7            //
//           !&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Y  :#@@@@@@&7:..:?&@@@@@@#:            //
//           [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#.  [email protected]@@@@@@@&##&@@@@@@@@!             //
//           [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B.   !#@@@@@@@@@@@@@@@@#!              //
//           [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B     [email protected]@@@@@@@@@@&G?.               //
//           .YGBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB5^        ^!JYPPPPYJ!:                  //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract OOG is ERC721Creator {
    constructor() ERC721Creator("Out of Gas, Out of Time", "OOG") {}
}