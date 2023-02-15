// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ARTFREAK x AI
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////
//                                                                 //
//                                                                 //
//    ____ ____ ___ ____ ____ ____ ____ _  _    _  _    ____ _     //
//    |__| |__/  |  |___ |__/ |___ |__| |_/      \/     |__| |     //
//    |  | |  \  |  |    |  \ |___ |  | | \_    _/\_    |  | |     //
//                                                                 //
//                                                                 //
//                                                                 //
//                                                                 //
//                                                                 //
/////////////////////////////////////////////////////////////////////


contract ARTAI is ERC1155Creator {
    constructor() ERC1155Creator("ARTFREAK x AI", "ARTAI") {}
}