// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: evbuilds
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////
//                           //
//                           //
//     _   |_    o| _| _     //
//    (/_\/|_)|_|||(_|_>     //
//                           //
//                           //
///////////////////////////////


contract evbuilds is ERC721Creator {
    constructor() ERC721Creator("evbuilds", "evbuilds") {}
}