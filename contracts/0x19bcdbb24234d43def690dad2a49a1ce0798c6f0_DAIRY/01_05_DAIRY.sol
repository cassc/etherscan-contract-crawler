// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DAIRYLAND
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

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


contract DAIRY is ERC1155Creator {
    constructor() ERC1155Creator("DAIRYLAND", "DAIRY") {}
}