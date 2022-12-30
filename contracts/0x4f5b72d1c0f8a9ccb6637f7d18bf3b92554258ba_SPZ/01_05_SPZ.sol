// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Spazoid.xyz
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////
//                                                              //
//                                                              //
//      ____                       _     _                      //
//     / ___| _ __   __ _ _______ (_) __| | __  ___   _ ____    //
//     \___ \| '_ \ / _` |_  / _ \| |/ _` | \ \/ / | | |_  /    //
//      ___) | |_) | (_| |/ / (_) | | (_| |_ >  <| |_| |/ /     //
//     |____/| .__/ \__,_/___\___/|_|\__,_(_)_/\_\\__, /___|    //
//           |_|                                  |___/         //
//                                                              //
//                                                              //
//    NFT Marketplace by artists, for artists.                  //
//                                                              //
//                                                              //
//////////////////////////////////////////////////////////////////


contract SPZ is ERC721Creator {
    constructor() ERC721Creator("Spazoid.xyz", "SPZ") {}
}