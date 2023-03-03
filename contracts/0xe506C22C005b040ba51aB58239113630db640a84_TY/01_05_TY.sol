// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Tyslo1155
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////
//           //
//           //
//    :-)    //
//           //
//           //
///////////////


contract TY is ERC1155Creator {
    constructor() ERC1155Creator("Tyslo1155", "TY") {}
}