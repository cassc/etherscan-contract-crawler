// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bastardous Artwork
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////
//              //
//              //
//    BasART    //
//              //
//              //
//////////////////


contract BasART is ERC1155Creator {
    constructor() ERC1155Creator("Bastardous Artwork", "BasART") {}
}