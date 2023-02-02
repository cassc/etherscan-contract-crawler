// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Check Guevara
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////
//                     //
//                     //
//    CHECK GUEVARA    //
//                     //
//                     //
/////////////////////////


contract CG is ERC1155Creator {
    constructor() ERC1155Creator("Check Guevara", "CG") {}
}