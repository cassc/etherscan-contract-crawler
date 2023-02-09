// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: KEKTONE
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////
//               //
//               //
//    KEKTONE    //
//               //
//               //
///////////////////


contract KTONE is ERC1155Creator {
    constructor() ERC1155Creator("KEKTONE", "KTONE") {}
}