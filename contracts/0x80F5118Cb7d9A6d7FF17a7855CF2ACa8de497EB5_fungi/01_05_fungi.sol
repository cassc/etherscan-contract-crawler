// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Last Of Memes
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////
//                                                                           //
//                                                                           //
//         001001                                                            //
//      10100101001                                                          //
//    100101010100101                                                        //
//          001                                                              //
//           0                                                               //
//           11                                                              //
//          01                                                               //
//           11                                                              //
//          00                                                               //
//          00                                                               //
//          11                                                               //
//          00                                                               //
//           11                                                              //
//            11                                                             //
//             111                                                           //
//             010101011.pepe/memes/thelastofus/fungi.mushrooms."zombie".    //
//                                                                           //
//                                                                           //
//                                                                           //
//                                                                           //
///////////////////////////////////////////////////////////////////////////////


contract fungi is ERC1155Creator {
    constructor() ERC1155Creator("The Last Of Memes", "fungi") {}
}