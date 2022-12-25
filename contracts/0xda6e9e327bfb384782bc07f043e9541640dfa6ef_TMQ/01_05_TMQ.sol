// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Misty Queen
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//     +-+-+-+ +-+-+-+-+-+ +-+-+-+-+-+     //
//     |T|h|e| |M|i|s|t|y| |Q|u|e|e|n|     //
//     +-+-+-+ +-+-+-+-+-+ +-+-+-+-+-+     //
//                                         //
//                                         //
/////////////////////////////////////////////


contract TMQ is ERC721Creator {
    constructor() ERC721Creator("The Misty Queen", "TMQ") {}
}