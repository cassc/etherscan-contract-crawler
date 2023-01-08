// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Test FC
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    \\\\\\//////    //
//                    //
//                    //
////////////////////////


contract TEST is ERC721Creator {
    constructor() ERC721Creator("Test FC", "TEST") {}
}