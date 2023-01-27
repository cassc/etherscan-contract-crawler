// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MALFORMΞD
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////
//                                                         //
//                                                         //
//      __  __   _   _    ___ ___  ___ __  __ ___ ___      //
//     |  \/  | /_\ | |  | __/ _ \| _ \  \/  | __|   \     //
//     | |\/| |/ _ \| |__| _| (_) |   / |\/| | _|| |) |    //
//     |_|  |_/_/ \_\____|_| \___/|_|_\_|  |_|___|___/     //
//                                                         //
//                                                         //
/////////////////////////////////////////////////////////////


contract MLF is ERC721Creator {
    constructor() ERC721Creator(unicode"MALFORMΞD", "MLF") {}
}