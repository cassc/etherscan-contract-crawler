// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Melissa Wiederrecht Artwork
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////
//                                                                           //
//                                                                           //
//                                                                           //
//      __  __          _   _                          __          __        //
//     |  \/  |        | | (_)                         \ \        / /        //
//     | \  / |   ___  | |  _   ___   ___    __ _       \ \  /\  / /         //
//     | |\/| |  / _ \ | | | | / __| / __|  / _` |       \ \/  \/ /          //
//     | |  | | |  __/ | | | | \__ \ \__ \ | (_| |        \  /\  /     _     //
//     |_|  |_|  \___| |_| |_| |___/ |___/  \__,_|         \/  \/     (_)    //
//                                                                           //
//                                                                           //
//                                                                           //
//                                                                           //
///////////////////////////////////////////////////////////////////////////////


contract MWART is ERC721Creator {
    constructor() ERC721Creator("Melissa Wiederrecht Artwork", "MWART") {}
}