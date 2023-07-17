// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PepeStory
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//    ____________________  _________    //
//    \______   \______   \/   _____/    //
//     |     ___/|     ___/\_____  \     //
//     |    |    |    |    /        \    //
//     |____|    |____|   /_______  /    //
//                                \/     //
//                                       //
//                                       //
///////////////////////////////////////////


contract PPS is ERC721Creator {
    constructor() ERC721Creator("PepeStory", "PPS") {}
}