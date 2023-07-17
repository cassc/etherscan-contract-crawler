// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NICUP
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//                    //
//     +-+-+-+-+-+    //
//     |N|I|C|U|P|    //
//     +-+-+-+-+-+    //
//                    //
//                    //
//                    //
////////////////////////


contract nicup is ERC721Creator {
    constructor() ERC721Creator("NICUP", "nicup") {}
}