// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Satoshi Girl Genesis
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////
//                  //
//                  //
//    SATOSHI.AI    //
//                  //
//                  //
//////////////////////


contract SG000 is ERC1155Creator {
    constructor() ERC1155Creator("Satoshi Girl Genesis", "SG000") {}
}