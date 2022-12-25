// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Satsuki Minato Present Collection
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//    Satsuki Minato Present Collection    //
//                                         //
//                                         //
/////////////////////////////////////////////


contract SMPC is ERC1155Creator {
    constructor() ERC1155Creator("Satsuki Minato Present Collection", "SMPC") {}
}