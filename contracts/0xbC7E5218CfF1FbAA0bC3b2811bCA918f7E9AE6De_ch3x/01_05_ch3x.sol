// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ch3x
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//                                       //
//           .__    ________             //
//      ____ |  |__ \_____  \___  ___    //
//    _/ ___\|  |  \  _(__  <\  \/  /    //
//    \  \___|   Y  \/       \>    <     //
//     \___  >___|  /______  /__/\_ \    //
//         \/     \/       \/      \/    //
//                                       //
//                                       //
//                                       //
///////////////////////////////////////////


contract ch3x is ERC721Creator {
    constructor() ERC721Creator("ch3x", "ch3x") {}
}