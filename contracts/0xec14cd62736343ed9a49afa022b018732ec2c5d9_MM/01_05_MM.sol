// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 幻の湖
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////
//                           //
//                           //
//    MABOROSHI NO MIZŪMI    //
//                           //
//                           //
///////////////////////////////


contract MM is ERC1155Creator {
    constructor() ERC1155Creator(unicode"幻の湖", "MM") {}
}