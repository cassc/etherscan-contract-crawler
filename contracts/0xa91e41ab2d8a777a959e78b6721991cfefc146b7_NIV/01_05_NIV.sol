// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Nickos IV
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////
//           //
//           //
//    NIV    //
//           //
//           //
///////////////


contract NIV is ERC1155Creator {
    constructor() ERC1155Creator("Nickos IV", "NIV") {}
}