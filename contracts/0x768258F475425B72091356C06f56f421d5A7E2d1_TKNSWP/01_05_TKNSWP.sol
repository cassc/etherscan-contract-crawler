// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TokenSweep
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    ToKeNSWeeP    //
//                  //
//                  //
//////////////////////


contract TKNSWP is ERC721Creator {
    constructor() ERC721Creator("TokenSweep", "TKNSWP") {}
}