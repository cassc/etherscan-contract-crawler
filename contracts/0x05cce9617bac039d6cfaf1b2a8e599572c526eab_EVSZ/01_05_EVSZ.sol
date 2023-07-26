// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ELON VS ZUCKERBERG
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    ELON          //
//    ZUCKERBERG    //
//                  //
//                  //
//////////////////////


contract EVSZ is ERC721Creator {
    constructor() ERC721Creator("ELON VS ZUCKERBERG", "EVSZ") {}
}