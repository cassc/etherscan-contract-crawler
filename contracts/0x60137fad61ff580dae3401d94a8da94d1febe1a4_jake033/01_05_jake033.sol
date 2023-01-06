// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 0.33 JAKE
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////
//                 //
//                 //
//    0.33 JAKE    //
//                 //
//                 //
/////////////////////


contract jake033 is ERC1155Creator {
    constructor() ERC1155Creator("0.33 JAKE", "jake033") {}
}