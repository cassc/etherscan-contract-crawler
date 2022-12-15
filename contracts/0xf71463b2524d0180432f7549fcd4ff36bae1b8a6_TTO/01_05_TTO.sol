// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: T.T. Open Edition
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////
//               //
//               //
//    (/・ω・)/    //
//               //
//               //
///////////////////


contract TTO is ERC1155Creator {
    constructor() ERC1155Creator("T.T. Open Edition", "TTO") {}
}