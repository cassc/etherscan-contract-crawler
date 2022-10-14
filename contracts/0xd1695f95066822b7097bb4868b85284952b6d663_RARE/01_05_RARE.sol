// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Rare Art Collection
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////
//                                                                              //
//                                                                              //
//    Rare Art Collection with (RARE) Symbol is an International Art Studio.    //
//                                                                              //
//                                                                              //
//                                                                              //
//////////////////////////////////////////////////////////////////////////////////


contract RARE is ERC721Creator {
    constructor() ERC721Creator("Rare Art Collection", "RARE") {}
}