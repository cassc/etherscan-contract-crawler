// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: poobaloobs
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////
//             //
//             //
//    poobs    //
//             //
//             //
/////////////////


contract poobaloobs is ERC1155Creator {
    constructor() ERC1155Creator("poobaloobs", "poobaloobs") {}
}