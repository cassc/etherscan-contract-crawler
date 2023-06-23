// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Other World 1/1s
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////
//          //
//          //
//    XX    //
//          //
//          //
//////////////


contract OWXX is ERC721Creator {
    constructor() ERC721Creator("Other World 1/1s", "OWXX") {}
}