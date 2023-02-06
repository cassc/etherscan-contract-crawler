// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Gear Five
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////
//                   //
//                   //
//    General Sar    //
//                   //
//                   //
///////////////////////


contract GF is ERC1155Creator {
    constructor() ERC1155Creator("Gear Five", "GF") {}
}