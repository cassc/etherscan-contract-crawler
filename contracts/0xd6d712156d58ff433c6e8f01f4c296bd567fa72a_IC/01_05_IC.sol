// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Identity Crisis
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//    Identity Crisis    //
//                       //
//                       //
///////////////////////////


contract IC is ERC721Creator {
    constructor() ERC721Creator("Identity Crisis", "IC") {}
}