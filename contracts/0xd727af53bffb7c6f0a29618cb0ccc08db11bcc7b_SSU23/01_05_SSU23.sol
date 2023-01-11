// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sixstreetunder 1/1
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                          //
//                                                                                          //
//    The ongoing place for mints of Sixstreetunder / Craig Whitehead 1/1 work from 2023    //
//                                                                                          //
//                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////


contract SSU23 is ERC721Creator {
    constructor() ERC721Creator("Sixstreetunder 1/1", "SSU23") {}
}