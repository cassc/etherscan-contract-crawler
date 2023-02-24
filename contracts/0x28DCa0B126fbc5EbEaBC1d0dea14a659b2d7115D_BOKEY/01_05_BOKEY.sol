// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bored Ohms Key
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//    84 104 101  71 111 108 100 101 110  75 101 121    //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract BOKEY is ERC1155Creator {
    constructor() ERC1155Creator("Bored Ohms Key", "BOKEY") {}
}