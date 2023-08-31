// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: test721
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////
//          //
//          //
//    //    //
//          //
//          //
//////////////


contract t721 is ERC721Creator {
    constructor() ERC721Creator("test721", "t721") {}
}