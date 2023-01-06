// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 14 years
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////
//                 //
//                 //
//    "HBD-BTC"    //
//                 //
//                 //
/////////////////////


contract HBD is ERC1155Creator {
    constructor() ERC1155Creator("14 years", "HBD") {}
}