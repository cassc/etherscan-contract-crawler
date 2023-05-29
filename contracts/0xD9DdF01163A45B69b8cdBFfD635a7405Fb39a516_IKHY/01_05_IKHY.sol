// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ikehaya Pass
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////
//               //
//               //
//    ikehaya    //
//               //
//               //
///////////////////


contract IKHY is ERC1155Creator {
    constructor() ERC1155Creator("ikehaya Pass", "IKHY") {}
}