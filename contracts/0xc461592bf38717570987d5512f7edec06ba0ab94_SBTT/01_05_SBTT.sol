// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SBT
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////
//               //
//               //
//    (/・ω・)/    //
//               //
//               //
///////////////////


contract SBTT is ERC1155Creator {
    constructor() ERC1155Creator("SBT", "SBTT") {}
}