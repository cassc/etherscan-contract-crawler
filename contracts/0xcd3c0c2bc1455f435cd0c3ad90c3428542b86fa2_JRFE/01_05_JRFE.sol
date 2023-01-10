// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: JRF-E
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//    Editions by @jamesrichardfry    //
//                                    //
//                                    //
//                                    //
////////////////////////////////////////


contract JRFE is ERC721Creator {
    constructor() ERC721Creator("JRF-E", "JRFE") {}
}