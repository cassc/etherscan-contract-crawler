// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Knight
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//                                       //
//                                       //
//      _  __      _       _     _       //
//     | |/ /     (_)     | |   | |      //
//     | ' / _ __  _  __ _| |__ | |_     //
//     |  < | '_ \| |/ _` | '_ \| __|    //
//     | . \| | | | | (_| | | | | |_     //
//     |_|\_\_| |_|_|\__, |_| |_|\__|    //
//                    __/ |              //
//                   |___/               //
//                                       //
//                                       //
//                                       //
//                                       //
///////////////////////////////////////////


contract RA is ERC721Creator {
    constructor() ERC721Creator("The Knight", "RA") {}
}