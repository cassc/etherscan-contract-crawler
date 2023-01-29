// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 0xArtSpread / New Journey OEs
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

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


contract OxNJ is ERC721Creator {
    constructor() ERC721Creator("0xArtSpread / New Journey OEs", "OxNJ") {}
}