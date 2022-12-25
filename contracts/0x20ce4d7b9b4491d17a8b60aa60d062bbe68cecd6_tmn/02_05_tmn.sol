// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: tomoya's nft
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////
//              //
//              //
//    tomoya    //
//              //
//              //
//////////////////


contract tmn is ERC721Creator {
    constructor() ERC721Creator("tomoya's nft", "tmn") {}
}