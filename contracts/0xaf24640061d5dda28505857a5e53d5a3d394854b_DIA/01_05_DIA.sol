// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: No Rocks but Diamond
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////
//                                                           //
//                                                           //
//    ________  .__                                  .___    //
//    \______ \ |__|____    _____   ____   ____    __| _/    //
//     |    |  \|  \__  \  /     \ /  _ \ /    \  / __ |     //
//     |    `   \  |/ __ \|  Y Y  (  <_> )   |  \/ /_/ |     //
//    /_______  /__(____  /__|_|  /\____/|___|  /\____ |     //
//            \/        \/      \/            \/      \/     //
//                                                           //
//                                                           //
///////////////////////////////////////////////////////////////


contract DIA is ERC721Creator {
    constructor() ERC721Creator("No Rocks but Diamond", "DIA") {}
}