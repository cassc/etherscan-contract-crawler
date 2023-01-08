// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: WHO AM I?
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//     __      __ ________   .___      //
//    /  \    /  \\_____  \  |   |     //
//    \   \/\/   / /   |   \ |   |     //
//     \        / /    |    \|   |     //
//      \__/\  /  \_______  /|___|     //
//           \/           \/           //
//                                     //
//                                     //
//                                     //
/////////////////////////////////////////


contract WOI is ERC721Creator {
    constructor() ERC721Creator("WHO AM I?", "WOI") {}
}