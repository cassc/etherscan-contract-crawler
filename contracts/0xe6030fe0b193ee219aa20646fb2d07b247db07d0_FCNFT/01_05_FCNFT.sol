// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FuckedNFT
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////
//                  //
//                  //
//    f5ck1ngn4t    //
//                  //
//                  //
//////////////////////


contract FCNFT is ERC721Creator {
    constructor() ERC721Creator("FuckedNFT", "FCNFT") {}
}