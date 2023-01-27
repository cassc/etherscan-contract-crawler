// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: arabpunks
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////
//                      //
//                      //
//    arabpunks labs    //
//                      //
//                      //
//////////////////////////


contract apart is ERC1155Creator {
    constructor() ERC1155Creator("arabpunks", "apart") {}
}