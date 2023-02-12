// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MKH ART
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////
//             //
//             //
//    -MKH-    //
//             //
//             //
/////////////////


contract MKH is ERC1155Creator {
    constructor() ERC1155Creator("MKH ART", "MKH") {}
}