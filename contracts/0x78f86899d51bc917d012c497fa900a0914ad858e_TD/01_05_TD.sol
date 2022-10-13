// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Teardrop
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//    A portrait of someone from the future.    //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract TD is ERC721Creator {
    constructor() ERC721Creator("Teardrop", "TD") {}
}