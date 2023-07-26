// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PFPepen
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////
//                         //
//                         //
//    SEIZE THE CULTURE    //
//                         //
//                         //
/////////////////////////////


contract PFP is ERC1155Creator {
    constructor() ERC1155Creator("PFPepen", "PFP") {}
}