// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Test Contract
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//    Hey! No clever ASCII art here.     //
//                                       //
//                                       //
///////////////////////////////////////////


contract TSCNTRT is ERC721Creator {
    constructor() ERC721Creator("Test Contract", "TSCNTRT") {}
}