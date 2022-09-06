// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Vintage Toy Store
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//                                                 //
//                                                 //
//                                                 //
//                                                 //
//                                                 //
//    o   o o-O-o o   o o-O-o   O   o-o  o--o      //
//    |   |   |   |\  |   |    / \ o     |         //
//    o   o   |   | \ |   |   o---o|  -o O-o       //
//     \ /    |   |  \|   |   |   |o   | |         //
//      o   o-O-o o   o   o   o   o o-o  o--o      //
//                                                 //
//                                                 //
//    o-O-o               o-o   o                  //
//      |                |      |                  //
//      |   o-o o  o      o-o  -o- o-o o-o o-o     //
//      |   | | |  |         |  |  | | |   |-'     //
//      o   o-o o--O     o--o   o  o-o o   o-o     //
//                 |                               //
//              o--o                               //
//                                                 //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract VTTS is ERC721Creator {
    constructor() ERC721Creator("The Vintage Toy Store", "VTTS") {}
}