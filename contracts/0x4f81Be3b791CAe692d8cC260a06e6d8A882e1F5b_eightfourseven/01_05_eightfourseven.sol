// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 847.xyz
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////
//               //
//               //
//    847.xyz    //
//               //
//               //
///////////////////


contract eightfourseven is ERC721Creator {
    constructor() ERC721Creator("847.xyz", "eightfourseven") {}
}