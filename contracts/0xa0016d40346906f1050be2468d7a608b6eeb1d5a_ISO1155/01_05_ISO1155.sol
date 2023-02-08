// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ISO 1155
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//                                          //
//       ____________    __________ ____    //
//      /  _/ __/ __ \  <  <  / __// __/    //
//     _/ /_\ \/ /_/ /  / // /__ \/__ \     //
//    /___/___/\____/  /_//_/____/____/     //
//                                          //
//                                          //
//                                          //
//                                          //
//////////////////////////////////////////////


contract ISO1155 is ERC1155Creator {
    constructor() ERC1155Creator("ISO 1155", "ISO1155") {}
}