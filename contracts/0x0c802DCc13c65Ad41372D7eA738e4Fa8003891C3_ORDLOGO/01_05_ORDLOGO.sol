// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ordinals Logo Voting Mechanism
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////
//                                                           //
//                                                           //
//                     .___.__              .__              //
//      ___________  __| _/|__| ____ _____  |  |   ______    //
//     /  _ \_  __ \/ __ | |  |/    \\__  \ |  |  /  ___/    //
//    (  <_> )  | \/ /_/ | |  |   |  \/ __ \|  |__\___ \     //
//     \____/|__|  \____ | |__|___|  (____  /____/____  >    //
//                      \/         \/     \/          \/     //
//                                                           //
//                                                           //
///////////////////////////////////////////////////////////////


contract ORDLOGO is ERC1155Creator {
    constructor() ERC1155Creator("Ordinals Logo Voting Mechanism", "ORDLOGO") {}
}