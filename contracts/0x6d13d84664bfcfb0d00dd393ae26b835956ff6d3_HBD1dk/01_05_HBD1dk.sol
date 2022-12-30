// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 1dk BD
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//                                                 //
//     ____    ._____     __________________       //
//    /_   | __| _/  | __ \______   \______ \      //
//     |   |/ __ ||  |/ /  |    |  _/|    |  \     //
//     |   / /_/ ||    <   |    |   \|    `   \    //
//     |___\____ ||__|_ \  |______  /_______  /    //
//              \/     \/         \/        \/     //
//                                                 //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract HBD1dk is ERC721Creator {
    constructor() ERC721Creator("1dk BD", "HBD1dk") {}
}