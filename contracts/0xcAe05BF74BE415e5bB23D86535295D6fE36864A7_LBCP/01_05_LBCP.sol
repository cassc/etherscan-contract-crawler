// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Lizard Brain Community Project
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//    .____   _____________________________     //
//    |    |  \______   \_   ___ \______   \    //
//    |    |   |    |  _/    \  \/|     ___/    //
//    |    |___|    |   \     \___|    |        //
//    |_______ \______  /\______  /____|        //
//            \/      \/        \/              //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract LBCP is ERC721Creator {
    constructor() ERC721Creator("Lizard Brain Community Project", "LBCP") {}
}