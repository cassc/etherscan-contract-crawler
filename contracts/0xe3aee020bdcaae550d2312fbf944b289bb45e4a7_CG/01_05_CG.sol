// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Cho-Gen
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////
//               //
//               //
//    Cho-Gen    //
//               //
//               //
///////////////////


contract CG is ERC1155Creator {
    constructor() ERC1155Creator("Cho-Gen", "CG") {}
}