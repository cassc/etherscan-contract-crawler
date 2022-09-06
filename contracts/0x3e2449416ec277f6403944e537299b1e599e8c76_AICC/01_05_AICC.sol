// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Alchemist Imaging Core Collection
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//    ___________      .__                     //
//    \__    ___/____  |  |   ____   ____      //
//      |    |  \__  \ |  |  /  _ \ /    \     //
//      |    |   / __ \|  |_(  <_> )   |  \    //
//      |____|  (____  /____/\____/|___|  /    //
//                   \/                 \/     //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract AICC is ERC721Creator {
    constructor() ERC721Creator("Alchemist Imaging Core Collection", "AICC") {}
}