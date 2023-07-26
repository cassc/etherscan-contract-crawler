// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Hope
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////
//                                                                 //
//                                                                 //
//    In a world full of hate, you need to be able to HOPE.        //
//    In a world full of evil, you need to be able to FORGIVE.     //
//    In a world full of despair, you need to be able to DREAM.    //
//    In a world full of doubts, you need to be able to BELIVE.    //
//                                                                 //
//                                                                 //
/////////////////////////////////////////////////////////////////////


contract HopeS is ERC1155Creator {
    constructor() ERC1155Creator("Hope", "HopeS") {}
}