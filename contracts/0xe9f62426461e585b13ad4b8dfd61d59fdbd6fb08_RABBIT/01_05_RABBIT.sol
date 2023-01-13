// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: RabbitYear
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//    __________         ___.    ___.    .__   __       //
//    \______   \_____   \_ |__  \_ |__  |__|_/  |_     //
//     |       _/\__  \   | __ \  | __ \ |  |\   __\    //
//     |    |   \ / __ \_ | \_\ \ | \_\ \|  | |  |      //
//     |____|_  /(____  / |___  / |___  /|__| |__|      //
//            \/      \/      \/      \/                //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract RABBIT is ERC721Creator {
    constructor() ERC721Creator("RabbitYear", "RABBIT") {}
}