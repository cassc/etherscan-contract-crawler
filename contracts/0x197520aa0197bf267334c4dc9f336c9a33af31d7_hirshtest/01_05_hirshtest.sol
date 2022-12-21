// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Hirshtest
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////
//          //
//          //
//    hi    //
//          //
//          //
//////////////


contract hirshtest is ERC721Creator {
    constructor() ERC721Creator("Hirshtest", "hirshtest") {}
}