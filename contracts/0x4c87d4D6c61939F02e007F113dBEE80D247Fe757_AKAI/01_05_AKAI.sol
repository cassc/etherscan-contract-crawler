// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ANORAK ART
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////
//                                                                //
//                                                                //
//    This is the beginning of a new experiment. Please enjoy.    //
//                                                                //
//                 Bear market is for building                    //
//                                                                //
//                                                                //
////////////////////////////////////////////////////////////////////


contract AKAI is ERC1155Creator {
    constructor() ERC1155Creator("ANORAK ART", "AKAI") {}
}