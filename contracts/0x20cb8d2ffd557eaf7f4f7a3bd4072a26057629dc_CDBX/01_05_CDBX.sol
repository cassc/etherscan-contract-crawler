// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CRYPRODUBX
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    CRYPRODUBX    //
//                  //
//                  //
//////////////////////


contract CDBX is ERC721Creator {
    constructor() ERC721Creator("CRYPRODUBX", "CDBX") {}
}