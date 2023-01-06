// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: properpablo
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//            __    __                         __       //
//    _____ _/  |__/  |_  ____   _____ _______/  |_     //
//    \__  \\   __\   __\/ __ \ /     \\____ \   __\    //
//     / __ \|  |  |  | \  ___/|  Y Y  \  |_> >  |      //
//    (____  /__|  |__|  \___  >__|_|  /   __/|__|      //
//         \/                \/      \/|__|             //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract pp is ERC721Creator {
    constructor() ERC721Creator("properpablo", "pp") {}
}