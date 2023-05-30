// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GM GUP
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////
//                                                                         //
//                                                                         //
//    Everyone should have a gm cup to start their day with good vibes.    //
//                                                                         //
//                                                                         //
/////////////////////////////////////////////////////////////////////////////


contract GMC is ERC721Creator {
    constructor() ERC721Creator("GM GUP", "GMC") {}
}