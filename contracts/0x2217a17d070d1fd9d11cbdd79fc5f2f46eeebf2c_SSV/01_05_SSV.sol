// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SvetarinaArt
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//    █▀ █░█ █▀▀ ▀█▀ ▄▀█ █▀█ █ █▄░█ ▄▀█    //
//    ▄█ ▀▄▀ ██▄ ░█░ █▀█ █▀▄ █ █░▀█ █▀█    //
//                                         //
//                                         //
/////////////////////////////////////////////


contract SSV is ERC721Creator {
    constructor() ERC721Creator("SvetarinaArt", "SSV") {}
}