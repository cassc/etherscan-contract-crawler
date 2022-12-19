// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Namporn #001
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////
//                                                             //
//                                                             //
//     _______                                                 //
//     \      \ _____    _____ ______   ___________  ____      //
//     /   |   \\__  \  /     \\____ \ /  _ \_  __ \/    \     //
//    /    |    \/ __ \|  Y Y  \  |_> >  <_> )  | \/   |  \    //
//    \____|__  (____  /__|_|  /   __/ \____/|__|  |___|  /    //
//            \/     \/      \/|__|                     \/     //
//                                                             //
//                                                             //
/////////////////////////////////////////////////////////////////


contract SWAITHAI is ERC721Creator {
    constructor() ERC721Creator("Namporn #001", "SWAITHAI") {}
}