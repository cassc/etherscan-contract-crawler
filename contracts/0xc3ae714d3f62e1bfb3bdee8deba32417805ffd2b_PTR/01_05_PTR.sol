// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PRAY FOR TURKEY
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////
//                       //
//                       //
//    PRAY FOR TURKEY    //
//                       //
//                       //
///////////////////////////


contract PTR is ERC1155Creator {
    constructor() ERC1155Creator("PRAY FOR TURKEY", "PTR") {}
}