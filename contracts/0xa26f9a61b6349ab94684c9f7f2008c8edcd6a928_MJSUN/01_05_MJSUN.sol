// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Solar System
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////
//                          //
//                          //
//    -=]solar system[=-    //
//                          //
//                          //
//////////////////////////////


contract MJSUN is ERC721Creator {
    constructor() ERC721Creator("Solar System", "MJSUN") {}
}