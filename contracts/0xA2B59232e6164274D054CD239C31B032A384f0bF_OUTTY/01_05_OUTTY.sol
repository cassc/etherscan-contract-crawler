// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Outer Heaven
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////
//          //
//          //
//    //    //
//          //
//          //
//////////////


contract OUTTY is ERC721Creator {
    constructor() ERC721Creator("Outer Heaven", "OUTTY") {}
}