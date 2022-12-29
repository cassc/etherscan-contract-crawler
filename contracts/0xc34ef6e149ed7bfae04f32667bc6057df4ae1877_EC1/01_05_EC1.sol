// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Exploration
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    -- EXPLORE --    //
//                     //
//                     //
/////////////////////////


contract EC1 is ERC721Creator {
    constructor() ERC721Creator("Exploration", "EC1") {}
}