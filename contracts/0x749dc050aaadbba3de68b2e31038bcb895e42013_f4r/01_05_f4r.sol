// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: f4r
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////
//           //
//           //
//    f4r    //
//           //
//           //
///////////////


contract f4r is ERC1155Creator {
    constructor() ERC1155Creator("f4r", "f4r") {}
}