// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: twemoji by AnonymouzNFT
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////
//                      //
//                      //
//    🆃🆆🅴🅼🅾🅹🅸    //
//                      //
//                      //
//////////////////////////


contract twmj is ERC721Creator {
    constructor() ERC721Creator("twemoji by AnonymouzNFT", "twmj") {}
}