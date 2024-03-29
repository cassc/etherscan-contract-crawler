// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Wojak Balloon
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////
//                                                                           //
//                                                                           //
//                                                                           //
//                                                                           //
//     _       __        _       __      ____        ____                    //
//    | |     / ____    (_____ _/ /__   / __ )____ _/ / ____  ____  ____     //
//    | | /| / / __ \  / / __ `/ //_/  / __  / __ `/ / / __ \/ __ \/ __ \    //
//    | |/ |/ / /_/ / / / /_/ / ,<    / /_/ / /_/ / / / /_/ / /_/ / / / /    //
//    |__/|__/\______/ /\__,_/_/|_|  /_____/\__,_/_/_/\____/\____/_/ /_/     //
//                /___/                                                      //
//                                                                           //
//                                                                           //
///////////////////////////////////////////////////////////////////////////////


contract WOB is ERC1155Creator {
    constructor() ERC1155Creator("Wojak Balloon", "WOB") {}
}