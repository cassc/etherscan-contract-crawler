// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Kenshiro
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////
//                           //
//                           //
//    $KEN$ TEST CONTRACT    //
//                           //
//                           //
///////////////////////////////


contract KEN is ERC1155Creator {
    constructor() ERC1155Creator("Kenshiro", "KEN") {}
}