// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Test 1
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//                                          //
//    ___________              __  ____     //
//    \__    ___/___   _______/  |/_   |    //
//      |    |_/ __ \ /  ___/\   __\   |    //
//      |    |\  ___/ \___ \  |  | |   |    //
//      |____| \___  >____  > |__| |___|    //
//                 \/     \/                //
//                                          //
//                                          //
//                                          //
//////////////////////////////////////////////


contract TS1 is ERC721Creator {
    constructor() ERC721Creator("Test 1", "TS1") {}
}