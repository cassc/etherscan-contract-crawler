// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TheHomeInventor
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////
//               //
//               //
//    /GOTO10    //
//               //
//               //
///////////////////


contract HOMIN is ERC1155Creator {
    constructor() ERC1155Creator("TheHomeInventor", "HOMIN") {}
}