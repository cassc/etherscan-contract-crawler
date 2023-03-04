// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: F022
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////
//                          //
//                          //
//    F022------editions    //
//    by @felixlepeintre    //
//                          //
//                          //
//////////////////////////////


contract F022 is ERC1155Creator {
    constructor() ERC1155Creator("F022", "F022") {}
}