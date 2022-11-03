// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: When The Lights Go Out
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////
//                          //
//                          //
//    AsH the Neptunian     //
//                          //
//                          //
//////////////////////////////


contract GEN is ERC721Creator {
    constructor() ERC721Creator("When The Lights Go Out", "GEN") {}
}