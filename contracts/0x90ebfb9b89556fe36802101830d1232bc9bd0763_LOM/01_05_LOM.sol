// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Life of Miyuki
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////
//              //
//              //
//    Miyuki    //
//              //
//              //
//////////////////


contract LOM is ERC1155Creator {
    constructor() ERC1155Creator("Life of Miyuki", "LOM") {}
}