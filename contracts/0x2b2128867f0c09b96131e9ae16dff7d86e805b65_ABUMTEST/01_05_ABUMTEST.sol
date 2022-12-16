// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AlbumTesting
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////
//          //
//          //
//    <>    //
//          //
//          //
//////////////


contract ABUMTEST is ERC721Creator {
    constructor() ERC721Creator("AlbumTesting", "ABUMTEST") {}
}