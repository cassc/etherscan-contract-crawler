// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: awd
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////
//           //
//           //
//    awd    //
//           //
//           //
///////////////


contract awd is ERC721Creator {
    constructor() ERC721Creator("awd", "awd") {}
}