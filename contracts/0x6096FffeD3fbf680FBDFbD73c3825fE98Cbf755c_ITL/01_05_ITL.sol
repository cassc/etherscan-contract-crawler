// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: INTERLUDE
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////
//                                                    //
//                                                    //
//                                                    //
//      ___ _  _ _____ ___ ___ _   _   _ ___  ___     //
//     |_ _| \| |_   _| __| _ \ | | | | |   \| __|    //
//      | || .` | | | | _||   / |_| |_| | |) | _|     //
//     |___|_|\_| |_| |___|_|_\____\___/|___/|___|    //
//                                                    //
//                                                    //
//                                                    //
//                                                    //
////////////////////////////////////////////////////////


contract ITL is ERC721Creator {
    constructor() ERC721Creator("INTERLUDE", "ITL") {}
}