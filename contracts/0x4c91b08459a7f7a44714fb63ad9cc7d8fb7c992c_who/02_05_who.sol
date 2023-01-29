// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Who Am I
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////
//           //
//           //
//    ???    //
//           //
//           //
///////////////


contract who is ERC1155Creator {
    constructor() ERC1155Creator("Who Am I", "who") {}
}