// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PEPE TALE
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//    vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv    //
//    vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv    //
//    vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv    //
//    vvvvvvvvvvvvvvvvvvvvvvvvvvvgggggggvvvvvvvvvvgaaagggggvvvvvvvvvvvvvvvvvvvvvvvvvvv    //
//    vvvvvvvvvvvvvvvvvvvvvvvagggggggggggggglvgggggggggggggggglvvvvvvvvvvvvvvvvvvvvvvv    //
//    vvvvvvvvvvvvvvvvvvvvvggggggggggggggggggggggggggggggggggggglvvvvvvvvvvvvvvvvvvvvv    //
//    vvvvvvvvvvvvvvvvvvvvvgggggnllllllllvgggggggllllllllllvggggggvvvvvvvvvvvvvvvvvvvv    //
//    vvvvvvvvvvvvvvvvvvvvggggllvvaggggalvvlaggllvvvgagggglvvlvggglvvvvvvvvvvvvvvvvvvv    //
//    vvvvvvvvvvvvvvvvvvaggggggvaggggggggggggggggggggggggggglvvagggllvvvvvvvvvvvvvvvvv    //
//    vvvvvvvvvvvvvvvvgggggggggggggggggggggggggggggggggggggggggggggggggvvvvvvvvvvvvvvv    //
//    vvvvvvvvvvvvvvaggggggggggggggggggggggggggggggggggggggggggggggggggggvvvvvvvvvvvvv    //
//    vvvvvvvvvvvvvggggggggggggggggggggggggggggggggggggggggggggggggggggggglvvvvvvvvvvv    //
//    vvvvvvvvvvvvgggggggggggganlllllllvvvvvvvvvvvvvvlllllllllnggggggggggggvvvvvvvvvvv    //
//    vvvvvvvvvvvagggggglllllvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvlllvgggggglvvvvvvvvvv    //
//    vvvvvvvvvvvgggggllvvvvvvvvvvvgaaggggggggggggggggaaggvvvvvvvvvvvvagggglvvvvvvvvvv    //
//    vvvvvvvvvvagggggggvvgaggggggggggggggggggggggggggggggggggggggvvvvvggggavvvvvvvvvv    //
//    vvvvvvvvvvagggggggggggggggggggggggggggggggggggggggggggggggggggggggggglvvvvvvvvvv    //
//    vvvvvvvvvvagggggggggggggggggggggggggggggggggggggggggggggggggggggggggalvvvvvvvvvv    //
//    vvvvvvvvvvvagggggggggggggggggggggggggggggggggggggggggggggggggggggggglvvvvvvvvvvv    //
//    vvvvvvvvvvvvvgggggggggggggggggggggggggggggggggggggggggggggggggggggalvvvvvvvvvvvv    //
//    vvvvvvvvvvvvvlgggggggggggggggggggggggggggggggggggggggggggggggggggllvvvvvvvvvvvvv    //
//    vvvvvvvvvvvvvvvlgggggggggggggggggggggggggggggggggggggggggggggggllvvvvvvvvvvvvvvv    //
//    vvvvvvvvvvvvvvvvvllgggggggggggggggggggggggggggggggggggggggggallvvvvvvvvvvvvvvvvv    //
//    vvvvvvvvvvvvvvvvvvvvvllllgggggggggggggggggggggggggggggganlllvvvvvvvvvvvvvvvvvvvv    //
//    vvvvvvvvvvvvvvvvvvvvvvvvvvgggggggggggggggggggggggggggggglvvvvvvvvvvvvvvvvvvvvvvv    //
//    vvvvvvvvvvvvvvvvvvvvvvvvgggggggggggggggggggggggggggggggggggvvvvvvvvvvvvvvvvvvvvv    //
//    vvvvvvvvvvvvvvvvvvvvvggggggggggggggggggggggggggggggggggggggggvvvvvvvvvvvvvvvvvvv    //
//    vvvvvvvvvvvvvvvvvvvvaggggggggggggggggggggggggggggggggggggggggglvvvvvvvvvvvvvvvvv    //
//    vvvvvvvvvvvvvvvvvvggggggggggggggggggggggggggggggggggggggggggggggvvvvvvvvvvvvvvvv    //
//    vvvvvvvvvvvvvvvvvggggggggggggggggggggggggggggggggggggggggggggggglvvvvvvvvvvvvvvv    //
//    vvvvvvvvvvvvvvvvvgggggggggggggggggggggggggggggggggggggggggggggggglvvvvvvvvvvvvvv    //
//    vvvvvvvvvvvvvvvvaggggggggggggggggggggggggggggggggggggggggggggggggglvvvvvvvvvvvvv    //
//    vvvvvvvvvvvvvvvagggggggggggggggggggggggggggggggggggggggggggggggggglvvvvvvvvvvvvv    //
//    vvvvvvvvvvvvvvvgggggggggggggggggggggggggggggggggggggggggggggggggggglvvvvvvvvvvvv    //
//    vvvvvvvvvvvvvvvgggggggggggggggggggggggggggggggggggggggggggggggggggglvvvvvvvvvvvv    //
//    vvvvvvvvvvvvvvaggggggggggggggggggggggggggggggggggggggggggggggggggggglvvvvvvvvvvv    //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract PEPESTRY is ERC721Creator {
    constructor() ERC721Creator("PEPE TALE", "PEPESTRY") {}
}