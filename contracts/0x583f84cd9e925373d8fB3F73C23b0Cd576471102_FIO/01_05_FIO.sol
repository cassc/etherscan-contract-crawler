// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Figuring It Out
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////
//                         //
//                         //
//    ғɪɢᴜʀɪɴɢ ɪᴛ ᴏᴜᴛ      //
//    ʙʏ ᴅᴇᴠᴏɴ ғɪɢᴜʀᴇs.    //
//                         //
//                         //
/////////////////////////////


contract FIO is ERC1155Creator {
    constructor() ERC1155Creator("Figuring It Out", "FIO") {}
}