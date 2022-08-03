// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BreadlyToast
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////
//                                                             //
//                                                             //
//     _____               _ _     _____             _         //
//    | __  |___ ___ ___ _| | |_ _|_   _|___ ___ ___| |_       //
//    | __ -|  _| -_| .'| . | | | | | | | . | .'|_ -|  _|      //
//    |_____|_| |___|__,|___|_|_  | |_| |___|__,|___|_|        //
//                            |___|                            //
//                                                             //
//                                                             //
/////////////////////////////////////////////////////////////////


contract BRDLY is ERC721Creator {
    constructor() ERC721Creator("BreadlyToast", "BRDLY") {}
}