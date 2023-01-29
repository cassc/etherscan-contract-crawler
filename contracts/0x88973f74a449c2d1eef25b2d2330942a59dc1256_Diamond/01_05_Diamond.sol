// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Diamond X Sako Asko
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//      _____ _____          __  __  ____  _   _ _____      //
//     |  __ \_   _|   /\   |  \/  |/ __ \| \ | |  __ \     //
//     | |  | || |    /  \  | \  / | |  | |  \| | |  | |    //
//     | |  | || |   / /\ \ | |\/| | |  | | . ` | |  | |    //
//     | |__| || |_ / ____ \| |  | | |__| | |\  | |__| |    //
//     |_____/_____/_/    \_\_|  |_|\____/|_| \_|_____/     //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract Diamond is ERC721Creator {
    constructor() ERC721Creator("Diamond X Sako Asko", "Diamond") {}
}