// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Golden Trumps
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////
//                                                    //
//                                                    //
//                                                    //
//                                                    //
//      ________       .__       .___                 //
//     /  _____/  ____ |  |    __| _/____   ____      //
//    /   \  ___ /  _ \|  |   / __ |/ __ \ /    \     //
//    \    \_\  (  <_> )  |__/ /_/ \  ___/|   |  \    //
//     \______  /\____/|____/\____ |\___  >___|  /    //
//            \/                  \/    \/     \/     //
//                                                    //
//                                                    //
//                                                    //
//                                                    //
////////////////////////////////////////////////////////


contract GT is ERC721Creator {
    constructor() ERC721Creator("Golden Trumps", "GT") {}
}