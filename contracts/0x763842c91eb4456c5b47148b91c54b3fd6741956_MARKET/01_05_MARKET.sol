// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MARKET
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//    70 72 6F  73 65  71 75 69 73 71 75 65     //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract MARKET is ERC721Creator {
    constructor() ERC721Creator("MARKET", "MARKET") {}
}