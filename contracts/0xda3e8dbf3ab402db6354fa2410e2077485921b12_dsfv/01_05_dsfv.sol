// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: My first 1155
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////
//         //
//         //
//    3    //
//         //
//         //
/////////////


contract dsfv is ERC1155Creator {
    constructor() ERC1155Creator("My first 1155", "dsfv") {}
}