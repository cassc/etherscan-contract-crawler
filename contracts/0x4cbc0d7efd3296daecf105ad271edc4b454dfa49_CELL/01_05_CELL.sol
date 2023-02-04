// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Check Cells
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//                    //
//                    //
//     +-+-+-+-+-+    //
//     |C|e|l|l|s|    //
//     +-+-+-+-+-+    //
//                    //
//                    //
//                    //
//                    //
////////////////////////


contract CELL is ERC721Creator {
    constructor() ERC721Creator("Check Cells", "CELL") {}
}