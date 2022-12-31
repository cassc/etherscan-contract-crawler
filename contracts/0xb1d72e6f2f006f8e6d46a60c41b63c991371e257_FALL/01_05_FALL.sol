// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FALL
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//    ___________ _____   .____     .____          //
//    \_   _____//  _  \  |    |    |    |         //
//     |    __) /  /_\  \ |    |    |    |         //
//     |     \ /    |    \|    |___ |    |___      //
//     \___  / \____|__  /|_______ \|_______ \     //
//         \/          \/         \/        \/     //
//                                                 //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract FALL is ERC721Creator {
    constructor() ERC721Creator("FALL", "FALL") {}
}