// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sunna
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                            //
//                                                                                                                                            //
//    The sun Goddesses represent the power and force of the light of the sun. Sunna is know for her warm, gentle, and mature personality.    //
//                                                                                                                                            //
//    The First of 13 Goddess to be revealed.                                                                                                 //
//                                                                                                                                            //
//                                                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SNA is ERC721Creator {
    constructor() ERC721Creator("Sunna", "SNA") {}
}