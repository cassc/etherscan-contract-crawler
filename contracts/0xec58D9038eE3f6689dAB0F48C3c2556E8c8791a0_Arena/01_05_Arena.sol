// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ArenaStar
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////
//                           //
//                           //
//    ArenaStar by Suphub    //
//                           //
//                           //
///////////////////////////////


contract Arena is ERC721Creator {
    constructor() ERC721Creator("ArenaStar", "Arena") {}
}