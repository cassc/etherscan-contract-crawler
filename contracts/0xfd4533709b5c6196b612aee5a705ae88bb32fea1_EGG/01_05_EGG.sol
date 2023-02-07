// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: EGG
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////
//                             //
//                             //
//    _____________________    //
//    3     33     33     3    //
//    |  ___!|   __!|   __!    //
//    |  __|_|  !  3|  !  3    //
//    |     3|     ||     |    //
//    !_____!!_____!!_____!    //
//                             //
//                             //
//                             //
/////////////////////////////////


contract EGG is ERC1155Creator {
    constructor() ERC1155Creator("EGG", "EGG") {}
}