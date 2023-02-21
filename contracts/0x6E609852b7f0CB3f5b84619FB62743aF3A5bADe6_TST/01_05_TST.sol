// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ExorzyTest
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////
//                  //
//                  //
//    EXORZYTEST    //
//                  //
//                  //
//////////////////////


contract TST is ERC1155Creator {
    constructor() ERC1155Creator("ExorzyTest", "TST") {}
}