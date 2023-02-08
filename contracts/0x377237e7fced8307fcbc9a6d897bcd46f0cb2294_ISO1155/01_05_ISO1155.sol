// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ISO (ERC-1155)
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

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


contract ISO1155 is ERC721Creator {
    constructor() ERC721Creator("ISO (ERC-1155)", "ISO1155") {}
}