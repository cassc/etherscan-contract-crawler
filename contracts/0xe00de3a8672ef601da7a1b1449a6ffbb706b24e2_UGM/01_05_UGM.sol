// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: UGM: Gramajo's Delivery Service
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//                                       //
//                                       //
//     ____ ___  ________    _____       //
//    |    |   \/  _____/   /     \      //
//    |    |   /   \  ___  /  \ /  \     //
//    |    |  /\    \_\  \/    Y    \    //
//    |______/  \______  /\____|__  /    //
//                     \/         \/     //
//                                       //
//                                       //
//                                       //
//                                       //
///////////////////////////////////////////


contract UGM is ERC721Creator {
    constructor() ERC721Creator("UGM: Gramajo's Delivery Service", "UGM") {}
}