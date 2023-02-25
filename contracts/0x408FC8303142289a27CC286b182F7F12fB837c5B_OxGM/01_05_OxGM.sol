// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GM or Die x 0xCoffee Utility Edition
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//                                                //
//                                                //
//     _____ __    _   _        _     _           //
//    |   __|  |  |_|_| |___   |_|___| |_ ___     //
//    |__   |  |__| | . | -_|  | |   |  _| . |    //
//    |_____|_____|_|___|___|  |_|_|_|_| |___|    //
//                                                //
//                                                //
//                  _____ _____                   //
//     _____ _ _   |   __|     |___               //
//    |     | | |  |  |  | | | |_ -|              //
//    |_|_|_|_  |  |_____|_|_|_|___|              //
//          |___|                                 //
//                                                //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract OxGM is ERC1155Creator {
    constructor() ERC1155Creator("GM or Die x 0xCoffee Utility Edition", "OxGM") {}
}