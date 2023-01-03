// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Art and The Artist
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//    |    |   \______   \___  _|__| ______ _____      //
//    |    |   /|       _/\  \/ /  |/  ___//     \     //
//    |    |  / |    |   \ \   /|  |\___ \|  Y Y  \    //
//    |______/  |____|_  /  \_/ |__/____  >__|_|  /    //
//                     \/               \/      \/     //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract TaTa is ERC721Creator {
    constructor() ERC721Creator("The Art and The Artist", "TaTa") {}
}