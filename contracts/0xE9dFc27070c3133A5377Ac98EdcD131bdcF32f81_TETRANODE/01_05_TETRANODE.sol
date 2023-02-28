// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TETRANODE
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////
//                     //
//                     //
//    I DUMP ON YOU    //
//                     //
//                     //
/////////////////////////


contract TETRANODE is ERC1155Creator {
    constructor() ERC1155Creator("TETRANODE", "TETRANODE") {}
}