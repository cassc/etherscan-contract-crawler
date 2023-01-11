// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CRYPTODUBX
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    CRYPTODUBX    //
//                  //
//                  //
//////////////////////


contract CDBX is ERC721Creator {
    constructor() ERC721Creator("CRYPTODUBX", "CDBX") {}
}