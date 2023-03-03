// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DREAM | GBA
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//    __________                .__.__       //
//    \______   \_____    _____ |__|  |      //
//     |       _/\__  \  /     \|  |  |      //
//     |    |   \ / __ \|  Y Y  \  |  |__    //
//     |____|_  /(____  /__|_|  /__|____/    //
//            \/      \/      \/             //
//                                           //
//                                           //
///////////////////////////////////////////////


contract GBA is ERC721Creator {
    constructor() ERC721Creator("DREAM | GBA", "GBA") {}
}