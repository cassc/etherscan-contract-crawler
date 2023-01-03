// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: THE OUTCAST
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////
//           //
//           //
//    OUT    //
//           //
//           //
///////////////


contract OUT is ERC1155Creator {
    constructor() ERC1155Creator("THE OUTCAST", "OUT") {}
}