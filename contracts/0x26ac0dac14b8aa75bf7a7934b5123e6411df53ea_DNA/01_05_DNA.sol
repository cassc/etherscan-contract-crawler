// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: XX111&M3
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////
//                                                                  //
//                                                                  //
//    O       o O       o O       o                                 //
//    | O   o | | O   o | | O   o |0001010101010                    //
//    | | O | | | | O | | | | O | |1001001010101010...XX111 & M3    //
//    | o   O | | o   O | | o   O |1001010101010                    //
//    o       O o       O o       O                                 //
//                                                                  //
//    CPUBL00DG3N30L0GY DEPARTMENT.                                 //
//                                                                  //
//                                                                  //
//////////////////////////////////////////////////////////////////////


contract DNA is ERC721Creator {
    constructor() ERC721Creator("XX111&M3", "DNA") {}
}