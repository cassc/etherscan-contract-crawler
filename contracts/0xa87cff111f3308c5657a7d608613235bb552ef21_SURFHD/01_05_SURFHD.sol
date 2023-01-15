// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Deep Challenger
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////
//                //
//                //
//    //[🌊]\\    //
//                //
//                //
////////////////////


contract SURFHD is ERC1155Creator {
    constructor() ERC1155Creator("Deep Challenger", "SURFHD") {}
}