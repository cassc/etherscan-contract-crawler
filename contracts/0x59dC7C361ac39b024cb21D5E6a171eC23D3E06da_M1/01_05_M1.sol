// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Moledarma
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//                                                     //
//    ][\/][ [[]] ][_ ]E ][_) //-\ ][2 ][\/][ //-\     //
//                                                     //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract M1 is ERC721Creator {
    constructor() ERC721Creator("Moledarma", "M1") {}
}