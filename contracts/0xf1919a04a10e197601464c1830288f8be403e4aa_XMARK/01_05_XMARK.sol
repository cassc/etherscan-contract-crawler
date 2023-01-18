// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: X-MARKs the SPOT
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//    X  X    xx xx xxxx xxx x x    //
//     xx  xx x x x x  x x   xx     //
//    x  x    x   x x  x x   x x    //
//                                  //
//                                  //
//////////////////////////////////////


contract XMARK is ERC1155Creator {
    constructor() ERC1155Creator("X-MARKs the SPOT", "XMARK") {}
}