// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Jpeg da Vinci Doors
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                      //
//                                                                                                                                                      //
//    Step into my office.                                                                                                                              //
//                                                                                                                                                      //
//    A door on a house can tell you a lot about a house’s life and the humans that have passed through, adding their love and trauma along the way.    //
//                                                                                                                                                      //
//    Houses with character have and beauty like no other, such is the same with humans who have character.                                             //
//                                                                                                                                                      //
//    Love all in the world.                                                                                                                            //
//                                                                                                                                                      //
//    PunkHunter.eth                                                                                                                                    //
//                                                                                                                                                      //
//                                                                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract JDVD is ERC721Creator {
    constructor() ERC721Creator("Jpeg da Vinci Doors", "JDVD") {}
}