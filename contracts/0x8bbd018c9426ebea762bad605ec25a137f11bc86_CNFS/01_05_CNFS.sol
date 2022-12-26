// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Cloudy Nowhere Friends Symbol
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////
//                                     //
//                                     //
//    Cloudy Nowhere Friends Symbol    //
//                                     //
//                                     //
/////////////////////////////////////////


contract CNFS is ERC721Creator {
    constructor() ERC721Creator("Cloudy Nowhere Friends Symbol", "CNFS") {}
}