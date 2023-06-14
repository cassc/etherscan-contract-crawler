// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: items
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////
//                                                               //
//                                                               //
//                                                               //
//    88                                                         //
//    ""    ,d                                                   //
//          88                                                   //
//    88  MM88MMM  ,adPPYba,  88,dPYba,,adPYba,   ,adPPYba,      //
//    88    88    a8P_____88  88P'   "88"    "8a  I8[    ""      //
//    88    88    8PP"""""""  88      88      88   `"Y8ba,       //
//    88    88,   "8b,   ,aa  88      88      88  aa    ]8I      //
//    88    "Y888  `"Ybbd8"'  88      88      88  `"YbbdP"'      //
//                                                               //
//                                                               //
//                                                               //
///////////////////////////////////////////////////////////////////


contract items is ERC721Creator {
    constructor() ERC721Creator("items", "items") {}
}