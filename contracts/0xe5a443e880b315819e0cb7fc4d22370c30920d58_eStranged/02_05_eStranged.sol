// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: eStranged
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//         __,                                  //
//        (    _/_                       /      //
//     _   `.  /  _   __,  _   _,  _  __/       //
//    (/_(___)(__/ (_(_/(_/ /_(_)_(/_(_/_       //
//                             /|               //
//                            (/                //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract eStranged is ERC721Creator {
    constructor() ERC721Creator("eStranged", "eStranged") {}
}