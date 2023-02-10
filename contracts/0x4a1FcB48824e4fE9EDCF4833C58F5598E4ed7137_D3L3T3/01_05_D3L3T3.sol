// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: D3L3T3
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//     ____ ____ ____ ____ ____ ____     //
//    ||D |||3 |||L |||3 |||T |||3 ||    //
//    ||__|||__|||__|||__|||__|||__||    //
//    |/__\|/__\|/__\|/__\|/__\|/__\|    //
//                                       //
//                                       //
///////////////////////////////////////////


contract D3L3T3 is ERC1155Creator {
    constructor() ERC1155Creator("D3L3T3", "D3L3T3") {}
}