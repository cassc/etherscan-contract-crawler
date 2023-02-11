// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ARTIZANS
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////
//                                                  //
//                                                  //
//    0x892cEC5232C3213b179569d1FeB7eA2AF725A110    //
//                                                  //
//                                                  //
//////////////////////////////////////////////////////


contract art101 is ERC721Creator {
    constructor() ERC721Creator("ARTIZANS", "art101") {}
}