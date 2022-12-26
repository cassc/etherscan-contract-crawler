// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AhCoraRare
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//    AhCoraRare & OneLoveForNFT    //
//                                  //
//                                  //
//////////////////////////////////////


contract AHCORA is ERC721Creator {
    constructor() ERC721Creator("AhCoraRare", "AHCORA") {}
}