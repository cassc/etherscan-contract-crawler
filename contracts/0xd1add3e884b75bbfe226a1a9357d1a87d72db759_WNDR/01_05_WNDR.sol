// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: WonderFi Hackathon
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//    WonderFi                      //
//    Hackathon Event NFT - 2022    //
//                                  //
//                                  //
//                                  //
//////////////////////////////////////


contract WNDR is ERC721Creator {
    constructor() ERC721Creator("WonderFi Hackathon", "WNDR") {}
}