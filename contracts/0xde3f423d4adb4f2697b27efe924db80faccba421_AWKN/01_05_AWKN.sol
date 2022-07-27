// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AWAKEN
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//         .    .       __     .    .     .____  __    _    //
//        /|    /       |     /|    /   / /      |\   |     //
//       /  \   |       |    /  \   |_-'  |__.   | \  |     //
//      /---'\  |  /\   /   /---'\  |  \  |      |  \ |     //
//    ,'      \ |,'  \,'  ,'      \ /   \ /----/ |   \|     //
//                                                          //
//                                                          //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract AWKN is ERC721Creator {
    constructor() ERC721Creator("AWAKEN", "AWKN") {}
}