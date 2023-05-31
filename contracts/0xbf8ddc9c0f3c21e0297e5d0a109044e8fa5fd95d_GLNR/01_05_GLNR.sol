// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: G-Liners 2.0
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//      ________                     __                //
//     /  _____/___________  ______ |  |__   ____      //
//    /   \  __\_  __ \__  \ |   _ \|  |  \_/ __ \     //
//    \    \_\  \  | \// __ \|  |_> >   |  \  ___/     //
//     \______  /__|  (____  /   __/|___|__/\____>     //
//            \/           \/|__|                      //
//                                                     //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract GLNR is ERC721Creator {
    constructor() ERC721Creator("G-Liners 2.0", "GLNR") {}
}