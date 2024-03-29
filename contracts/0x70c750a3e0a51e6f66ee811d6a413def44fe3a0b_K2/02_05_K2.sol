// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: KDROPS
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////
//                                                                             //
//                                                                             //
//                                                                             //
//    ,-. .-.,---.    ,---.  ,---.  ,---.    .---. .-. .-. .---.  .-.  .-.     //
//    | |/ / | .-.\   | .-'  | .-'  | .-.\  ( .-._)| | | |/ .-. ) | |/\| |     //
//    | | /  | `-'/   | `-.  | `-.  | |-' )(_) \   | `-' || | |(_)| /  \ |     //
//    | | \  |   (    | .-'  | .-'  | |--' _  \ \  | .-. || | | | |  /\  |     //
//    | |) \ | |\ \   |  `--.|  `--.| |   ( `-'  ) | | |)|\ `-' / |(/  \ |     //
//    |((_)-'|_| \)\  /( __.'/( __.'/(     `----'  /(  (_) )---'  (_)   \|     //
//    (_)        (__)(__)   (__)   (__)           (__)    (_)                  //
//                                                                             //
//                                                                             //
/////////////////////////////////////////////////////////////////////////////////


contract K2 is ERC721Creator {
    constructor() ERC721Creator("KDROPS", "K2") {}
}