// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Flow_eth
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//                                                      //
//      ____|  |                         |    |         //
//      |      |   _ \ \ \  \   /   _ \  __|  __ \      //
//      __|    |  (   | \ \  \ /    __/  |    | | |     //
//     _|     _| \___/   \_/\_/   \___| \__| _| |_|     //
//                            _____|                    //
//                                                      //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract floweth is ERC721Creator {
    constructor() ERC721Creator("Flow_eth", "floweth") {}
}