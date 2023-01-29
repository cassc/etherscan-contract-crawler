// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 0xArtSpread / New Journey OEs
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


contract OxASNJ is ERC1155Creator {
    constructor() ERC1155Creator("0xArtSpread / New Journey OEs", "OxASNJ") {}
}