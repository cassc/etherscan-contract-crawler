// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CheckPass
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////
//                 //
//                 //
//    CheckPass    //
//                 //
//                 //
//                 //
/////////////////////


contract CheckPass is ERC1155Creator {
    constructor() ERC1155Creator("CheckPass", "CheckPass") {}
}