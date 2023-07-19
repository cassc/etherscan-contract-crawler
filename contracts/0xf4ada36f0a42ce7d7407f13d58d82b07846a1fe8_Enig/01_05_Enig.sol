// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Enigma
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////
//                                                     //
//                                                     //
//    `7MM"""YMM  `7MN.   `7MF'`7MMF' .g8"""bgd        //
//      MM    `7    MMN.    M    MM .dP'     `M        //
//      MM   d      M YMb   M    MM dM'       `        //
//      MMmDmMM      M  `AMN. M    MM MM               //
//      MM   Y  ,   M   `MM.M    MMA MM.    `7MMFS'    //
//      MM     ,M   M     YMM    MM `Mb.     MM        //
//    .JMMmmmmMMM .JML.    YM  .JMML. `"NbmmmdPY       //
//                                                     //
//                                                     //
//                                                     //
/////////////////////////////////////////////////////////


contract Enig is ERC721Creator {
    constructor() ERC721Creator("Enigma", "Enig") {}
}