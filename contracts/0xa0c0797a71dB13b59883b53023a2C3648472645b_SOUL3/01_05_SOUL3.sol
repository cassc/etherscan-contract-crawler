// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SOUL3
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////
//             //
//             //
//    SOUL3    //
//             //
//             //
/////////////////


contract SOUL3 is ERC1155Creator {
    constructor() ERC1155Creator("SOUL3", "SOUL3") {}
}