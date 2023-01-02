// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TOILART
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////
//               //
//               //
//    TOILART    //
//               //
//               //
///////////////////


contract TLRT is ERC1155Creator {
    constructor() ERC1155Creator("TOILART", "TLRT") {}
}