// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Punk'd
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////
//           //
//           //
//    SJL    //
//           //
//           //
///////////////


contract SJL is ERC1155Creator {
    constructor() ERC1155Creator("Punk'd", "SJL") {}
}