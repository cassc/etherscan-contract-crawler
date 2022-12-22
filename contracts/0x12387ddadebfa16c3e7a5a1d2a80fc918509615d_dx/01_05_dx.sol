// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: dx
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////
//             //
//             //
//    dxxxd    //
//             //
//             //
/////////////////


contract dx is ERC1155Creator {
    constructor() ERC1155Creator("dx", "dx") {}
}