// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Evveart
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//                                                      //
//                                             __       //
//      _______  _____  __ ____ _____ ________/  |_     //
//    _/ __ \  \/ /\  \/ // __ \\__  \\_  __ \   __\    //
//    \  ___/\   /  \   /\  ___/ / __ \|  | \/|  |      //
//     \___  >\_/    \_/  \___  >____  /__|   |__|      //
//         \/                 \/     \/                 //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract EVVE is ERC721Creator {
    constructor() ERC721Creator("Evveart", "EVVE") {}
}