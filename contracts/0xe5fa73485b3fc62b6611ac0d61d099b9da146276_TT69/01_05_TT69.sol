// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Test test69
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//      __                   __       //
//    _/  |_  ____   _______/  |_     //
//    \   __\/ __ \ /  ___/\   __\    //
//     |  | \  ___/ \___ \  |  |      //
//     |__|  \___  >____  > |__|      //
//               \/     \/            //
//                                    //
//                                    //
////////////////////////////////////////


contract TT69 is ERC721Creator {
    constructor() ERC721Creator("Test test69", "TT69") {}
}