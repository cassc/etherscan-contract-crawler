// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: first ever (LR)
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////
//                       //
//                       //
//    first ever (LR)    //
//                       //
//                       //
///////////////////////////


contract feLR is ERC1155Creator {
    constructor() ERC1155Creator("first ever (LR)", "feLR") {}
}