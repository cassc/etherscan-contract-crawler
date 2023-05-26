// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Gen Art LP
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//    ------------------>>>>>>>    //
//                                 //
//                                 //
/////////////////////////////////////


contract GAL is ERC721Creator {
    constructor() ERC721Creator("Gen Art LP", "GAL") {}
}