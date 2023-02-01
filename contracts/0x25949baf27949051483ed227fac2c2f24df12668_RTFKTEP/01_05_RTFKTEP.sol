// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: RTFKT ExoPod
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    RTFKT ExoPod    //
//                    //
//                    //
////////////////////////


contract RTFKTEP is ERC721Creator {
    constructor() ERC721Creator("RTFKT ExoPod", "RTFKTEP") {}
}