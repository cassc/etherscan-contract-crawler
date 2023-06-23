// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Millö *a game of underdogs and naked cats*
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////
//                                                                       //
//                                                                       //
//    __________ ____ _____________  _______       _____  ___________    //
//    \______   \    |   \______   \ \      \     /     \ \_   _____/    //
//     |    |  _/    |   /|       _/ /   |   \   /  \ /  \ |    __)      //
//     |    |   \    |  / |    |   \/    |    \ /    Y    \|     \       //
//     |______  /______/  |____|_  /\____|__  / \____|__  /\___  /       //
//            \/                 \/         \/          \/     \/        //
//                                                                       //
//                                                                       //
///////////////////////////////////////////////////////////////////////////


contract MLLOBC is ERC721Creator {
    constructor() ERC721Creator(unicode"Millö *a game of underdogs and naked cats*", "MLLOBC") {}
}