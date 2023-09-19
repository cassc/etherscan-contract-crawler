// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: am202
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////
//           //
//           //
//    202    //
//           //
//           //
///////////////


contract am202 is ERC1155Creator {
    constructor() ERC1155Creator("am202", "am202") {}
}