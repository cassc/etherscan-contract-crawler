// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CC Forum London
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////
//                               //
//                               //
//    Powered by Earth Wallet    //
//                               //
//                               //
///////////////////////////////////


contract NFTrees is ERC721Creator {
    constructor() ERC721Creator("CC Forum London", "NFTrees") {}
}