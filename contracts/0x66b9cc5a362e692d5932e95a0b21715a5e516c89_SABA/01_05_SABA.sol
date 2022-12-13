// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: sabaart.ED
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//                                                  //
//      _________   _____ __________    _____       //
//     /   _____/  /  _  \\______   \  /  _  \      //
//     \_____  \  /  /_\  \|    |  _/ /  /_\  \     //
//     /        \/    |    \    |   \/    |    \    //
//    /_______  /\____|__  /______  /\____|__  /    //
//            \/         \/       \/         \/     //
//                                                  //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract SABA is ERC721Creator {
    constructor() ERC721Creator("sabaart.ED", "SABA") {}
}