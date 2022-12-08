// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: THICC
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////
//             //
//             //
//    THICC    //
//             //
//             //
/////////////////


contract THICC is ERC1155Creator {
    constructor() ERC1155Creator("THICC", "THICC") {}
}