// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Blue White
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////
//          //
//          //
//    BW    //
//          //
//          //
//////////////


contract BW is ERC721Creator {
    constructor() ERC721Creator("Blue White", "BW") {}
}