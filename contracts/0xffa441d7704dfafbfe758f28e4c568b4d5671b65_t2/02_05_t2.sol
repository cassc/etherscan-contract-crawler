// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Tester02
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////
//                             //
//                             //
//    TTTTTTTTT222222222222    //
//    -                   -    //
//    222222222222222222222    //
//                             //
//                             //
/////////////////////////////////


contract t2 is ERC1155Creator {
    constructor() ERC1155Creator("Tester02", "t2") {}
}