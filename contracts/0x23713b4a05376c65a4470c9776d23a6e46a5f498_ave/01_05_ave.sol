// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: avekno editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////
//         //
//         //
//         //
//         //
//         //
/////////////


contract ave is ERC1155Creator {
    constructor() ERC1155Creator("avekno editions", "ave") {}
}