// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ERC1155
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////
//               //
//               //
//    ERC1155    //
//               //
//               //
///////////////////


contract ERC is ERC1155Creator {
    constructor() ERC1155Creator("ERC1155", "ERC") {}
}