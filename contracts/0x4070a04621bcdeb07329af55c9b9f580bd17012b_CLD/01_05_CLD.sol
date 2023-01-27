// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Head in the clouds
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////
//               //
//               //
//    ( |_ |)    //
//               //
//               //
///////////////////


contract CLD is ERC721Creator {
    constructor() ERC721Creator("Head in the clouds", "CLD") {}
}