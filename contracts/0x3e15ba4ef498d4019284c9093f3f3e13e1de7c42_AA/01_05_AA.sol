// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AleyArtist
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////
//          //
//          //
//    AA    //
//          //
//          //
//////////////


contract AA is ERC1155Creator {
    constructor() ERC1155Creator("AleyArtist", "AA") {}
}