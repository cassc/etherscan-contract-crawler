// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BTCKID
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////
//                //
//                //
//    00000000    //
//                //
//                //
////////////////////


contract BK is ERC721Creator {
    constructor() ERC721Creator("BTCKID", "BK") {}
}