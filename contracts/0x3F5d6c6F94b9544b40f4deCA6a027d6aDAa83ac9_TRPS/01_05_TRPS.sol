// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TRIPS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////
//                                                                                //
//                                                                                //
//    Multidisciplinary artist driven by fractals, maths and generative means.    //
//                                                                                //
//                                                                                //
////////////////////////////////////////////////////////////////////////////////////


contract TRPS is ERC1155Creator {
    constructor() ERC1155Creator("TRIPS", "TRPS") {}
}