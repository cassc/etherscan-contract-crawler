// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: RB01 Development
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//    ___________.__                         //
//    \__    ___/|__| ____   ___________     //
//      |    |   |  |/ ___\_/ __ \_  __ \    //
//      |    |   |  / /_/  >  ___/|  | \/    //
//      |____|   |__\___  / \___  >__|       //
//                 /_____/      \/           //
//                                           //
//                                           //
///////////////////////////////////////////////


contract RB01D is ERC1155Creator {
    constructor() ERC1155Creator("RB01 Development", "RB01D") {}
}