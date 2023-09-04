// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: James Andrew Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////
//                                                         //
//                                                         //
//               .___.__  __  .__                          //
//      ____   __| _/|__|/  |_|__| ____   ____   ______    //
//    _/ __ \ / __ | |  \   __\  |/  _ \ /    \ /  ___/    //
//    \  ___// /_/ | |  ||  | |  (  <_> )   |  \\___ \     //
//     \___  >____ | |__||__| |__|\____/|___|  /____  >    //
//         \/     \/                         \/     \/     //
//                                                         //
//                                                         //
//                                                         //
//                                                         //
//                                                         //
/////////////////////////////////////////////////////////////


contract JMAE is ERC1155Creator {
    constructor() ERC1155Creator("James Andrew Editions", "JMAE") {}
}