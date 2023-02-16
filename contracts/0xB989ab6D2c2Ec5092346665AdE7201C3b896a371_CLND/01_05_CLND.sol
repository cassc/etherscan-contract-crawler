// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CLAND
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////
//           //
//           //
//    LFG    //
//           //
//           //
///////////////


contract CLND is ERC1155Creator {
    constructor() ERC1155Creator("CLAND", "CLND") {}
}