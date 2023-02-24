// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: THE LIGHT
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////
//                           //
//                           //
//    *******************    //
//    |T|h|e| |L|i|g|h|t|    //
//    *******************    //
//                           //
//                           //
///////////////////////////////


contract THELIGHT is ERC1155Creator {
    constructor() ERC1155Creator("THE LIGHT", "THELIGHT") {}
}