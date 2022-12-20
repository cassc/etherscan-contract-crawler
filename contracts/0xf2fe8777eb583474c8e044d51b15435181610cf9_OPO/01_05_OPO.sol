// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: one plus one
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////
//           //
//           //
//    1+1    //
//           //
//           //
///////////////


contract OPO is ERC1155Creator {
    constructor() ERC1155Creator("one plus one", "OPO") {}
}