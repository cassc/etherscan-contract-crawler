// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Beaded Braids Study I
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                            //
//                                                                                                                            //
//    o--o  o--o   O  o-o   o--o o-o       o--o  o--o    O  o-O-o o-o    o-o       o-o  o-O-o o   o o-o   o   o     o-O-o     //
//    |   | |     / \ |  \  |    |  \      |   | |   |  / \   |   |  \  |         |       |   |   | |  \   \ /        |       //
//    O--o  O-o  o---o|   O O-o  |   O     O--o  O-Oo  o---o  |   |   O  o-o       o-o    |   |   | |   O   O         |       //
//    |   | |    |   ||  /  |    |  /      |   | |  \  |   |  |   |  /      |         |   |   |   | |  /    |         |       //
//    o--o  o--o o   oo-o   o--o o-o       o--o  o   o o   oo-O-o o-o   o--o      o--o    o    o-o  o-o     o       o-O-o     //
//                                                                                                                            //
//                                                                                                                            //
//                                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BBS is ERC721Creator {
    constructor() ERC721Creator("Beaded Braids Study I", "BBS") {}
}