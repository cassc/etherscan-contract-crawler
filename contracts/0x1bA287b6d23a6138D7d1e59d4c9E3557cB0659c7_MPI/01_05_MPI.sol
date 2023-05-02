// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MAX PEPE ICON
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////
//             //
//             //
//    🐸lol    //
//             //
//             //
/////////////////


contract MPI is ERC1155Creator {
    constructor() ERC1155Creator("MAX PEPE ICON", "MPI") {}
}