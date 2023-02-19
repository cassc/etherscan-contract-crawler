// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: UFOs by Area 69
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//    Unidentified Fluffy Oddities by Area 69    //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract UFOs is ERC721Creator {
    constructor() ERC721Creator("UFOs by Area 69", "UFOs") {}
}