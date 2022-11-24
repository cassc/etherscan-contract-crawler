// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Random Showcase
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//                                         //
//     +-+-+-+-+-+-+ +-+-+-+-+-+-+-+-+     //
//     |R|a|n|d|o|m| |S|h|o|w|c|a|s|e|     //
//     +-+-+-+-+-+-+ +-+-+-+-+-+-+-+-+     //
//                                         //
//                                         //
//                                         //
/////////////////////////////////////////////


contract RShwcase is ERC721Creator {
    constructor() ERC721Creator("Random Showcase", "RShwcase") {}
}