// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BadBeanLLC First Impressions
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////
//                              //
//                              //
//                              //
//                              //
//     +-+-+-+-+-+-+-+-+-+-+    //
//     |B|a|d|B|e|a|n|L|L|C|    //
//     +-+-+-+-+-+-+-+-+-+-+    //
//                              //
//                              //
//                              //
//                              //
//////////////////////////////////


contract BBLLC is ERC721Creator {
    constructor() ERC721Creator("BadBeanLLC First Impressions", "BBLLC") {}
}