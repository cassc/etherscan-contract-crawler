// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LittleFlyegG
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////
//           //
//           //
//    lfg    //
//           //
//           //
///////////////


contract egg is ERC1155Creator {
    constructor() ERC1155Creator("LittleFlyegG", "egg") {}
}