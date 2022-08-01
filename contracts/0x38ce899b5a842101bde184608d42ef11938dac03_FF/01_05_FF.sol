// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FFei
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////
//          //
//          //
//    FF    //
//          //
//          //
//////////////


contract FF is ERC721Creator {
    constructor() ERC721Creator("FFei", "FF") {}
}