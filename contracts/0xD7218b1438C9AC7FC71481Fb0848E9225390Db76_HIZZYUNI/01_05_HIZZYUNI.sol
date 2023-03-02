// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Hizzys Unicorn OE
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//                                                     //
//     ____ ___      .__                               //
//    |    |   \____ |__| ____  ___________  ____      //
//    |    |   /    \|  |/ ___\/  _ \_  __ \/    \     //
//    |    |  /   |  \  \  \__(  <_> )  | \/   |  \    //
//    |______/|___|  /__|\___  >____/|__|  |___|  /    //
//                 \/        \/                 \/     //
//                                                     //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract HIZZYUNI is ERC721Creator {
    constructor() ERC721Creator("Hizzys Unicorn OE", "HIZZYUNI") {}
}