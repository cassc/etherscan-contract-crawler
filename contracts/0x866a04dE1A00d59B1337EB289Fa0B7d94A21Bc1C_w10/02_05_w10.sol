// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: wed 10pm xyz
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////
//           //
//           //
//    w10    //
//           //
//           //
///////////////


contract w10 is ERC1155Creator {
    constructor() ERC1155Creator("wed 10pm xyz", "w10") {}
}