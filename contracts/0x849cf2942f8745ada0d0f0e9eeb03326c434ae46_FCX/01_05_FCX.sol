// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Flowers Collection
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//                                     //
//     _ __   ___   _____   ____ _     //
//    | '_ \ / _ \ / _ \ \ / / _` |    //
//    | |_) | (_) |  __/\ V / (_| |    //
//    | .__/ \___/ \___| \_/ \__,_|    //
//    |_|                              //
//                                     //
//                                     //
//                                     //
/////////////////////////////////////////


contract FCX is ERC721Creator {
    constructor() ERC721Creator("Flowers Collection", "FCX") {}
}