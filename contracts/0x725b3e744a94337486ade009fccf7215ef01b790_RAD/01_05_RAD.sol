// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Radical Experience
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////
//                                                      //
//                                                      //
//                       .___.__              .__       //
//    ____________     __| _/|__| ____ _____  |  |      //
//    \_  __ \__  \   / __ | |  |/ ___\\__  \ |  |      //
//     |  | \// __ \_/ /_/ | |  \  \___ / __ \|  |__    //
//     |__|  (____  /\____ | |__|\___  >____  /____/    //
//                \/      \/         \/     \/          //
//                                                      //
//                                                      //
//////////////////////////////////////////////////////////


contract RAD is ERC1155Creator {
    constructor() ERC1155Creator("Radical Experience", "RAD") {}
}