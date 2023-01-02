// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NARDO EXPERIMENTAL
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//    We become what we think about.    //
//                                      //
//                                      //
//////////////////////////////////////////


contract NARDEX is ERC721Creator {
    constructor() ERC721Creator("NARDO EXPERIMENTAL", "NARDEX") {}
}