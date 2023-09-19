// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PFPepen
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//    SEIZE THE CULTURE    //
//                         //
//                         //
/////////////////////////////


contract PFP is ERC721Creator {
    constructor() ERC721Creator("PFPepen", "PFP") {}
}