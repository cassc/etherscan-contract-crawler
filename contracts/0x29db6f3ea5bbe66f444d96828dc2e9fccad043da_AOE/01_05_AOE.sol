// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Arman Open Edition
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//    I'm a 2d Animator,                                    //
//    I create loops, Infinite loops, Loops in the loops    //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract AOE is ERC1155Creator {
    constructor() ERC1155Creator("Arman Open Edition", "AOE") {}
}