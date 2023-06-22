// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: WACK! Claim
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////
//                                                                //
//                                                                //
//                                                                //
//    by Camille Chiang @ WACK! contract                          //
//                                                                //
//                                                                //
////////////////////////////////////////////////////////////////////


contract WCKC is ERC721Creator {
    constructor() ERC721Creator("WACK! Claim", "WCKC") {}
}