// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Lofi Fam
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////
//                                                                      //
//                                                                      //
//                                                                      //
//     ___      _______  _______  ___     _______  _______  __   __     //
//    |   |    |       ||       ||   |   |       ||   _   ||  |_|  |    //
//    |   |    |   _   ||    ___||   |   |    ___||  |_|  ||       |    //
//    |   |    |  | |  ||   |___ |   |   |   |___ |       ||       |    //
//    |   |___ |  |_|  ||    ___||   |   |    ___||       ||       |    //
//    |       ||       ||   |    |   |   |   |    |   _   || ||_|| |    //
//    |_______||_______||___|    |___|   |___|    |__| |__||_|   |_|    //
//                                                                      //
//                                                                      //
//                                                                      //
//                                                                      //
//                                                                      //
//                                                                      //
//                                                                      //
//                                                                      //
//                                                                      //
//                                                                      //
//////////////////////////////////////////////////////////////////////////


contract LOFAM is ERC1155Creator {
    constructor() ERC1155Creator("Lofi Fam", "LOFAM") {}
}