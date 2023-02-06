// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DAIRYLAND
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//    ________      _____  .__________________.___.    //
//    \______ \    /  _  \ |   \______   \__  |   |    //
//     |    |  \  /  /_\  \|   ||       _//   |   |    //
//     |    `   \/    |    \   ||    |   \\____   |    //
//    /_______  /\____|__  /___||____|_  // ______|    //
//            \/         \/            \/ \/           //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract DAIRY is ERC721Creator {
    constructor() ERC721Creator("DAIRYLAND", "DAIRY") {}
}