// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GRMLN
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////
//               //
//               //
//    GRΞMLIN    //
//               //
//               //
///////////////////


contract GR is ERC1155Creator {
    constructor() ERC1155Creator("GRMLN", "GR") {}
}