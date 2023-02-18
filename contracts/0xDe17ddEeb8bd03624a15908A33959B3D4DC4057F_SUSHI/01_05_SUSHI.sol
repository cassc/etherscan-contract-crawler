// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SUSHI
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////
//             //
//             //
//    SUSHI    //
//             //
//             //
/////////////////


contract SUSHI is ERC1155Creator {
    constructor() ERC1155Creator("SUSHI", "SUSHI") {}
}