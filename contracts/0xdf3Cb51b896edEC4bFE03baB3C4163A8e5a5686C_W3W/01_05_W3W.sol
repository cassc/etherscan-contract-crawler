// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Web3Ware Badge
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////
//           //
//           //
//    W3W    //
//           //
//           //
///////////////


contract W3W is ERC1155Creator {
    constructor() ERC1155Creator("Web3Ware Badge", "W3W") {}
}