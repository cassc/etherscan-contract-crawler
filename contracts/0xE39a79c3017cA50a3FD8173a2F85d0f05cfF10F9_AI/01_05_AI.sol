// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: OrdinalAI
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//    The Brain Will Update And Be Scraped!    //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract AI is ERC721Creator {
    constructor() ERC721Creator("OrdinalAI", "AI") {}
}