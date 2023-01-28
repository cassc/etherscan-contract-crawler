// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Touch of Red
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//      _______    ____    _____    ______   _____      //
//     |__   __|  / __ \  |  __ \  |  ____| |  __ \     //
//        | |    | |  | | | |__) | | |__    | |  | |    //
//        | |    | |  | | |  _  /  |  __|   | |  | |    //
//        | |    | |__| | | | \ \  | |____  | |__| |    //
//        |_|     \____/  |_|  \_\ |______| |_____/     //
//                                                      //
//                                                      //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract TORED is ERC721Creator {
    constructor() ERC721Creator("Touch of Red", "TORED") {}
}