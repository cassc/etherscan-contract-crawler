// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Verified Visual Art
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////
//                             //
//                             //
//    This is verified art.    //
//                             //
//                             //
/////////////////////////////////


contract VVA is ERC1155Creator {
    constructor() ERC1155Creator("Verified Visual Art", "VVA") {}
}