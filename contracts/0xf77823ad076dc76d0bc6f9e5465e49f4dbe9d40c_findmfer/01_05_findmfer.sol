// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: find the mfer
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////
//                                                           //
//                                                           //
//    .__                              _____                 //
//    |__| ____________ ___.__. ______/ ____\___________     //
//    |  |/  ___/\____ <   |  |/     \   __\/ __ \_  __ \    //
//    |  |\___ \ |  |_> >___  |  Y Y  \  | \  ___/|  | \/    //
//    |__/____  >|   __// ____|__|_|  /__|  \___  >__|       //
//            \/ |__|   \/          \/          \/           //
//                                                           //
//                                                           //
///////////////////////////////////////////////////////////////


contract findmfer is ERC721Creator {
    constructor() ERC721Creator("find the mfer", "findmfer") {}
}