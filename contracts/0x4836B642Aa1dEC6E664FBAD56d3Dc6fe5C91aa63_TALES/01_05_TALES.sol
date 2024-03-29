// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Slimie Tales
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////
//                                                             //
//                                                             //
//                                                             //
//      ____  _ _           _        _____     _               //
//     / ___|| (_)_ __ ___ (_) ___  |_   _|_ _| | ___  ___     //
//     \___ \| | | '_ ` _ \| |/ _ \   | |/ _` | |/ _ \/ __|    //
//      ___) | | | | | | | | |  __/   | | (_| | |  __/\__ \    //
//     |____/|_|_|_| |_| |_|_|\___|   |_|\__,_|_|\___||___/    //
//                                                             //
//                                                             //
//                                                             //
//                                                             //
/////////////////////////////////////////////////////////////////


contract TALES is ERC721Creator {
    constructor() ERC721Creator("Slimie Tales", "TALES") {}
}