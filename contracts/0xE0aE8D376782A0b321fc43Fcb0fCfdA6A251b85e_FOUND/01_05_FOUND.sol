// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Foundation
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////
//               //
//               //
//    TAZENDA    //
//               //
//               //
///////////////////


contract FOUND is ERC1155Creator {
    constructor() ERC1155Creator("Foundation", "FOUND") {}
}