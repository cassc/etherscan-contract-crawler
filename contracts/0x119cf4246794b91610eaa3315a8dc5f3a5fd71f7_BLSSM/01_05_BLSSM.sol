// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BLOSSOM | 花
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////
//                                                       //
//                                                       //
//    ___.   .__                                         //
//    \_ |__ |  |   ____  ______ __________   _____      //
//     | __ \|  |  /  _ \/  ___//  ___/  _ \ /     \     //
//     | \_\ \  |_(  <_> )___ \ \___ (  <_> )  Y Y  \    //
//     |___  /____/\____/____  >____  >____/|__|_|  /    //
//         \/                \/     \/            \/     //
//                                                       //
//                                                       //
///////////////////////////////////////////////////////////


contract BLSSM is ERC721Creator {
    constructor() ERC721Creator(unicode"BLOSSOM | 花", "BLSSM") {}
}