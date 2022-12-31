// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sensory Overload
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//    _______                         ______            //
//    ___    |________ ______ ___________  /_ _____     //
//    __  /| |___  __ \_  __ `/_  ___/__  __ \_  _ \    //
//    _  ___ |__  /_/ // /_/ / / /__  _  / / //  __/    //
//    /_/  |_|_  .___/ \__,_/  \___/  /_/ /_/ \___/     //
//            /_/                                       //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract ROGUE is ERC721Creator {
    constructor() ERC721Creator("Sensory Overload", "ROGUE") {}
}