// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 0xArtSpread / For The Culture OEs
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////
//                                                                   //
//                                                                   //
//                                                                   //
//                                                                   //
//        ,--.         ,.       .  .---.                   .         //
//        |  | . ,    / |   ,-. |- \___  ,-. ,-. ,-. ,-. ,-|         //
//        |  |  X    /~~|-. |   |      \ | | |   |-' ,-| | |         //
//        `--' ' ` ,'   `-' '   `' `---' |-' '   `-' `-^ `-'         //
//                                       |                           //
//                                       '      By 0xFineArt         //
//                                                                   //
//                                                                   //
//                                                                   //
//                                                                   //
///////////////////////////////////////////////////////////////////////


contract OxASFTC is ERC1155Creator {
    constructor() ERC1155Creator("0xArtSpread / For The Culture OEs", "OxASFTC") {}
}