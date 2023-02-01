// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: RTFKT LuxPod
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    RTFKT LuxPod    //
//                    //
//                    //
////////////////////////


contract RTFKTLP is ERC721Creator {
    constructor() ERC721Creator("RTFKT LuxPod", "RTFKTLP") {}
}