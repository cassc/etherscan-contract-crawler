// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: somekindarobot666
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////
//               //
//               //
//    skr_666    //
//               //
//               //
///////////////////


contract skr is ERC1155Creator {
    constructor() ERC1155Creator("somekindarobot666", "skr") {}
}