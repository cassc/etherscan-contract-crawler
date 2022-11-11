// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SYNDICATE
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                           //
//                                                                                                           //
//                                                                                                           //
//                                                                                                           //
//     .M"""bgd `YMM'   `MM'`7MN.   `7MF'`7MM"""Yb. `7MMF' .g8"""bgd     db  MMP""MM""YMM `7MM"""YMM         //
//    ,MI    "Y   VMA   ,V    MMN.    M    MM    `Yb. MM .dP'     `M    ;MM: P'   MM   `7   MM    `7         //
//    `MMb.        VMA ,V     M YMb   M    MM     `Mb MM dM'       `   ,V^MM.     MM        MM   d           //
//      `YMMNq.     VMMP      M  `MN. M    MM      MM MM MM           ,M  `MM     MM        MMmmMM           //
//    .     `MM      MM       M   `MM.M    MM     ,MP MM MM.          AbmmmqMA    MM        MM   Y  ,        //
//    Mb     dM      MM       M     YMM    MM    ,dP' MM `Mb.     ,' A'     VML   MM        MM     ,M        //
//    P"Ybmmd"     .JMML.   .JML.    YM  .JMMmmmdP' .JMML. `"bmmmd'.AMA.   .AMMA.JMML.    .JMMmmmmMMM        //
//                                                                                                           //
//    by MEELO                                                                                               //
//                                                                                                           //
//                                                                                                           //
//                                                                                                           //
//                                                                                                           //
//                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SYN is ERC721Creator {
    constructor() ERC721Creator("SYNDICATE", "SYN") {}
}