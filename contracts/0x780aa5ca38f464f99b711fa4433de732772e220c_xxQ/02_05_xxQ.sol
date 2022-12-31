// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////
//           //
//           //
//    XxQ    //
//           //
//           //
///////////////


contract xxQ is ERC1155Creator {
    constructor() ERC1155Creator("editions", "xxQ") {}
}