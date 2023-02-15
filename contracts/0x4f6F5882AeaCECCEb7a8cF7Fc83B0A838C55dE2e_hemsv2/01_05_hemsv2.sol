// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Hemilylan Editions v2
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//    // hemilylan editions v2 <3+ //    //
//                                       //
//                                       //
///////////////////////////////////////////


contract hemsv2 is ERC1155Creator {
    constructor() ERC1155Creator("Hemilylan Editions v2", "hemsv2") {}
}