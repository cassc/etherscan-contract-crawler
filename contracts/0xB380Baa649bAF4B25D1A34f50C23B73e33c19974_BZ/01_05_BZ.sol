// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Learning Out Loud
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////
//                   //
//                   //
//    bazooka zac    //
//                   //
//                   //
///////////////////////


contract BZ is ERC1155Creator {
    constructor() ERC1155Creator("Learning Out Loud", "BZ") {}
}