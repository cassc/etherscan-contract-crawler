// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Conversations
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//     +-+-+-+-+-+-+-+-+-+-+-+-+-+    //
//     |C|o|n|v|e|r|s|a|t|i|o|n|s|    //
//     +-+-+-+-+-+-+-+-+-+-+-+-+-+    //
//                                    //
//                                    //
////////////////////////////////////////


contract CON is ERC721Creator {
    constructor() ERC721Creator("Conversations", "CON") {}
}