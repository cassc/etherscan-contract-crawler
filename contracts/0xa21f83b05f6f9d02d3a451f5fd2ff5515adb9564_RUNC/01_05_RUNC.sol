// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Running in Circles
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////
//             //
//             //
//    bleep    //
//             //
//             //
/////////////////


contract RUNC is ERC1155Creator {
    constructor() ERC1155Creator("Running in Circles", "RUNC") {}
}