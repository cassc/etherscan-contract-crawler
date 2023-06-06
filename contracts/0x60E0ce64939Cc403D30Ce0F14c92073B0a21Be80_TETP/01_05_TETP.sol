// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Entrance To Paradise
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//    The Entrance To Paradise (2023)    //
//                                       //
//                                       //
///////////////////////////////////////////


contract TETP is ERC721Creator {
    constructor() ERC721Creator("The Entrance To Paradise", "TETP") {}
}