// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Swarley
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//                                                 //
//       __|                     |                 //
//     \__ \ \ \  \ /  _` |   _| |   -_)  |  |     //
//     ____/  \_/\_/ \__,_| _|  _| \___| \_, |     //
//                                       ___/      //
//                                                 //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract Swarl is ERC721Creator {
    constructor() ERC721Creator("Swarley", "Swarl") {}
}