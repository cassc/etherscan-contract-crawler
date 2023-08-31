// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: My Art is Heclectik-Art
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////
//                               //
//                               //
//    My Art Is Heclectik-Art    //
//                               //
//                               //
///////////////////////////////////


contract Linho is ERC721Creator {
    constructor() ERC721Creator("My Art is Heclectik-Art", "Linho") {}
}