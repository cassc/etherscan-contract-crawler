// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Famous Landmarks
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////
//                          //
//                          //
//    ┌─┐┬─┐┌┬┐╔╗╔╔═╗╔╦╗    //
//    ├─┤├┬┘ │ ║║║╠╣  ║     //
//    ┴ ┴┴└─ ┴ ╝╚╝╚   ╩     //
//                          //
//                          //
//////////////////////////////


contract ArtNFT is ERC721Creator {
    constructor() ERC721Creator("Famous Landmarks", "ArtNFT") {}
}