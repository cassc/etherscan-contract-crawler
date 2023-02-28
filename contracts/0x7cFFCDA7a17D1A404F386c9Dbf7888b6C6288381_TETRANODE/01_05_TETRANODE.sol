// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TETRANODE
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    I DUMP ON YOU    //
//                     //
//                     //
/////////////////////////


contract TETRANODE is ERC721Creator {
    constructor() ERC721Creator("TETRANODE", "TETRANODE") {}
}