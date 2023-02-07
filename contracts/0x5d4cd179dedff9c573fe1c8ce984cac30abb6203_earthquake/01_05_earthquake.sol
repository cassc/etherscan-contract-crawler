// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 7.8
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////
//           //
//           //
//    7.8    //
//           //
//           //
///////////////


contract earthquake is ERC1155Creator {
    constructor() ERC1155Creator("7.8", "earthquake") {}
}