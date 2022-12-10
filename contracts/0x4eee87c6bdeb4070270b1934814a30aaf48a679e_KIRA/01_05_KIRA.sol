// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Artificial marooned -  //The tail of KIRA//
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////
//               //
//               //
//    KIRA-AI    //
//               //
//               //
///////////////////


contract KIRA is ERC1155Creator {
    constructor() ERC1155Creator("Artificial marooned -  //The tail of KIRA//", "KIRA") {}
}