// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Black/White - 1155 Test
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////
//         //
//         //
//         //
//         //
//         //
/////////////


contract TEST is ERC1155Creator {
    constructor() ERC1155Creator("Black/White - 1155 Test", "TEST") {}
}