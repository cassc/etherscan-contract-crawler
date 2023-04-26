// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Photography OEs
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////
//                                                                                  //
//                                                                                  //
//    115 99 101 110 105 99 10 10 112 104 111 116 111 103 114 97 112 104 121 10     //
//                                                                                  //
//                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////


contract POE is ERC1155Creator {
    constructor() ERC1155Creator("Photography OEs", "POE") {}
}