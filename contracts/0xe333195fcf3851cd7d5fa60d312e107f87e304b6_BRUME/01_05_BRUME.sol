// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Brume by Perrine
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//      __ )                                    //
//      __ \    __|  |   |  __ `__ \    _ \     //
//      |   |  |     |   |  |   |   |   __/     //
//     ____/  _|    \__,_| _|  _|  _| \___|     //
//                                              //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract BRUME is ERC721Creator {
    constructor() ERC721Creator("Brume by Perrine", "BRUME") {}
}