// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Linda Kristiansen - Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//       _       _  __  U _____ u ____        //
//      |"|     |"|/ /  \| ___"|/|  _"\       //
//    U | | u   | ' /    |  _|" /| | | |      //
//     \| |/__U/| . \\u  | |___ U| |_| |\     //
//      |_____| |_|\_\   |_____| |____/ u     //
//      //  \\,-,>> \\,-.<<   >>  |||_        //
//     (_")("_)\.)   (_/(__) (__)(__)_)       //
//                                            //
//                                            //
////////////////////////////////////////////////


contract LKED is ERC1155Creator {
    constructor() ERC1155Creator("Linda Kristiansen - Editions", "LKED") {}
}