// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BUSON Pass
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////
//               //
//               //
//    GENESIS    //
//               //
//               //
///////////////////


contract BUSON is ERC1155Creator {
    constructor() ERC1155Creator("BUSON Pass", "BUSON") {}
}