// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: of the Fu
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                         //
//                                                                                                                                                         //
//    consists of 13 layers, which are divided into Qingyuan sword and aon, Bodyguard sword and shield, sword shadow splitting, and Dageng sword array.    //
//                                                                                                                                                         //
//                                                                                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract OTF is ERC721Creator {
    constructor() ERC721Creator("of the Fu", "OTF") {}
}