// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FUZZ Edition
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////
//                //
//                //
//    FUZZGAFF    //
//                //
//                //
////////////////////


contract FUZZGAFF is ERC1155Creator {
    constructor() ERC1155Creator("FUZZ Edition", "FUZZGAFF") {}
}