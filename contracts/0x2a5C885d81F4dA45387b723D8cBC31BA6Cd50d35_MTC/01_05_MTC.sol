// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MisfitTestContract
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//                                                   //
//      __  __ _     __ _ _  _____ ___ ___ _____     //
//     |  \/  (_)___/ _(_) ||_   _| __/ __|_   _|    //
//     | |\/| | (_-<  _| |  _|| | | _|\__ \ | |      //
//     |_|  |_|_/__/_| |_|\__||_| |___|___/ |_|      //
//                                                   //
//                                                   //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract MTC is ERC721Creator {
    constructor() ERC721Creator("MisfitTestContract", "MTC") {}
}