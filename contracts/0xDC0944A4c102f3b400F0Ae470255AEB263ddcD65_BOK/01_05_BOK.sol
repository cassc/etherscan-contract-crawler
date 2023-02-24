// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BoredOhmsKey
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//    66 111 114 101 100 79 104 109 115 75 101 121     //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract BOK is ERC1155Creator {
    constructor() ERC1155Creator("BoredOhmsKey", "BOK") {}
}