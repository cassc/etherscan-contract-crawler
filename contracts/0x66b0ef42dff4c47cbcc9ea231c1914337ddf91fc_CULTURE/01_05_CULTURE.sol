// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: For The Culture
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////
//                                                                 //
//                                                                 //
//                                                                 //
//                                                                 //
//     _____         _____ _       _____     _ _                   //
//    |   __|___ ___|_   _| |_ ___|     |_ _| | |_ _ _ ___ ___     //
//    |   __| . |  _| | | |   | -_|   --| | | |  _| | |  _| -_|    //
//    |__|  |___|_|   |_| |_|_|___|_____|___|_|_| |___|_| |___|    //
//                                                                 //
//                                                                 //
//                                                                 //
//                                                                 //
/////////////////////////////////////////////////////////////////////


contract CULTURE is ERC1155Creator {
    constructor() ERC1155Creator("For The Culture", "CULTURE") {}
}