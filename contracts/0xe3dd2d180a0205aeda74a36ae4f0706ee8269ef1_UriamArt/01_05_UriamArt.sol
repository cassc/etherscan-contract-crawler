// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Uriam-Art
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////
//        //
//        //
//        //
//        //
//        //
//        //
//        //
////////////


contract UriamArt is ERC1155Creator {
    constructor() ERC1155Creator("Uriam-Art", "UriamArt") {}
}