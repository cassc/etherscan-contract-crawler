// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: POPWXVE
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////
//                                                         //
//                                                         //
//        ____  ____  ____ _       ___  ___    ________    //
//       / __ \/ __ \/ __ \ |     / / |/ / |  / / ____/    //
//      / /_/ / / / / /_/ / | /| / /|   /| | / / __/       //
//     / ____/ /_/ / ____/| |/ |/ //   | | |/ / /___       //
//    /_/    \____/_/     |__/|__//_/|_| |___/_____/       //
//                                                         //
//                                                         //
//                                                         //
/////////////////////////////////////////////////////////////


contract popwxve is ERC721Creator {
    constructor() ERC721Creator("POPWXVE", "popwxve") {}
}