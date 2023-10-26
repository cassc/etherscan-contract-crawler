// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Neon Void
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//                     //
//     _____ _____     //
//    |   | |  |  |    //
//    | | | |  |  |    //
//    |_|___|\___/     //
//                     //
//                     //
//                     //
//                     //
/////////////////////////


contract NV is ERC721Creator {
    constructor() ERC721Creator("Neon Void", "NV") {}
}