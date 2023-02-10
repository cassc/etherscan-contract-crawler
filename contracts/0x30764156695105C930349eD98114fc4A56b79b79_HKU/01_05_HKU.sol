// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: HKU
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//    The University of Hong Kong (HKU)    //
//                                         //
//                                         //
/////////////////////////////////////////////


contract HKU is ERC1155Creator {
    constructor() ERC1155Creator("HKU", "HKU") {}
}