// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Blue Velvet Red Silk
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                  //
//                                                                                                  //
//    __             ___          ___            ___ ___     __   ___  __      __                   //
//    |__) |    |  | |__     \  / |__  |    \  / |__   |     |__) |__  |  \    /__` | |    |__/     //
//    |__) |___ \__/ |___     \/  |___ |___  \/  |___  |     |  \ |___ |__/    .__/ | |___ |  \     //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////


contract BlueVelvet is ERC721Creator {
    constructor() ERC721Creator("Blue Velvet Red Silk", "BlueVelvet") {}
}