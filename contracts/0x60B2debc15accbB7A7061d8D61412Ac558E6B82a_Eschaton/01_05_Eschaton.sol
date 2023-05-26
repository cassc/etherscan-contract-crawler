// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fractilians - Concrescence of the Metaverse Eschaton
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//                                                                          //
//      _____                      __  .__.__  .__                          //
//    _/ ____\___________    _____/  |_|__|  | |__|____    ____   ______    //
//    \   __\\_  __ \__  \ _/ ___\   __\  |  | |  \__  \  /    \ /  ___/    //
//     |  |   |  | \// __ \\  \___|  | |  |  |_|  |/ __ \|   |  \\___ \     //
//     |__|   |__|  (____  /\___  >__| |__|____/__(____  /___|  /____  >    //
//                       \/     \/                     \/     \/     \/     //
//                                                                          //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////


contract Eschaton is ERC721Creator {
    constructor() ERC721Creator("Fractilians - Concrescence of the Metaverse Eschaton", "Eschaton") {}
}