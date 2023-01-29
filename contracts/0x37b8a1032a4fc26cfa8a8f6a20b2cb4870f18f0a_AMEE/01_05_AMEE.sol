// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Anastasios Melitas Escape Editions
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//                                                      //
//    ___________                                       //
//    \_   _____/ ______ ____ _____  ______   ____      //
//     |    __)_ /  ___// ___\\__  \ \____ \_/ __ \     //
//     |        \\___ \\  \___ / __ \|  |_> >  ___/     //
//    /_______  /____  >\___  >____  /   __/ \___  >    //
//            \/     \/     \/     \/|__|        \/     //
//                                                      //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract AMEE is ERC721Creator {
    constructor() ERC721Creator("Anastasios Melitas Escape Editions", "AMEE") {}
}