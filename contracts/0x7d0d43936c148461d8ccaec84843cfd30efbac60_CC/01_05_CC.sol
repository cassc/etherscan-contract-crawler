// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Crypto Cartoons
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////
//           //
//           //
//    Bee    //
//           //
//           //
///////////////


contract CC is ERC1155Creator {
    constructor() ERC1155Creator("Crypto Cartoons", "CC") {}
}