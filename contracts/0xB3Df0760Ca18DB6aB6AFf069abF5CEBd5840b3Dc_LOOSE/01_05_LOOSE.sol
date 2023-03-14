// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LOOSEleaf
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//      _________.__.__                         //
//     /   _____/|__|  |___  __ ___________     //
//     \_____  \ |  |  |\  \/ // __ \_  __ \    //
//     /        \|  |  |_\   /\  ___/|  | \/    //
//    /_______  /|__|____/\_/  \___  >__|       //
//            \/                   \/           //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract LOOSE is ERC721Creator {
    constructor() ERC721Creator("LOOSEleaf", "LOOSE") {}
}