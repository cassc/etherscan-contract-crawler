// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Cosaan
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////
//                                                                                       //
//                                                                                       //
//                                                                                       //
//     o-o    O  o   o   O      o       o o--o o   o o   o     o   o   O    O  o   o     //
//    |      / \ |\ /|  / \     |       | |     \ /  |   |     |\ /|  / \  / \ |\ /|     //
//     o-o  o---o| O | o---o    o   o   o O-o    O   |   |     | O | o---oo---o| O |     //
//        | |   ||   | |   |     \ / \ /  |      |   |   |     |   | |   ||   ||   |     //
//    o--o  o   oo   o o   o      o   o   o--o   o    o-o      o   o o   oo   oo   o     //
//                                                                                       //
//                                                                                       //
//                                                                                       //
//                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////


contract MAAM is ERC721Creator {
    constructor() ERC721Creator("Cosaan", "MAAM") {}
}