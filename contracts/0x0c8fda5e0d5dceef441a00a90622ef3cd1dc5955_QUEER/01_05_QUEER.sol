// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PRID3
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//                                               //
//                 .__    .___     ________      //
//    _____________|__| __| _/____ \_____  \     //
//    \____ \_  __ \  |/ __ |/ __ \  _(__  <     //
//    |  |_> >  | \/  / /_/ \  ___/ /       \    //
//    |   __/|__|  |__\____ |\___  >______  /    //
//    |__|                 \/    \/       \/     //
//                                               //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract QUEER is ERC721Creator {
    constructor() ERC721Creator("PRID3", "QUEER") {}
}