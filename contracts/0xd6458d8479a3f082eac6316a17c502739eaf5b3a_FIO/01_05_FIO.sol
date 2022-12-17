// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Figuring It Out
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//    ғɪɢᴜʀɪɴɢ ɪᴛ ᴏᴜᴛ      //
//    ʙʏ ᴅᴇᴠᴏɴ ғɪɢᴜʀᴇs.    //
//                         //
//                         //
/////////////////////////////


contract FIO is ERC721Creator {
    constructor() ERC721Creator("Figuring It Out", "FIO") {}
}