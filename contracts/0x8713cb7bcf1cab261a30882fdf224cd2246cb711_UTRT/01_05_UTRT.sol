// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Urban Transportation; Red Trucks
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//    Alejandro Cartagena Red Trucks     //
//                                       //
//                                       //
///////////////////////////////////////////


contract UTRT is ERC721Creator {
    constructor() ERC721Creator("Urban Transportation; Red Trucks", "UTRT") {}
}