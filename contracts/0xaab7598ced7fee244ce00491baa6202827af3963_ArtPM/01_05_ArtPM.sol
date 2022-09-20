// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TheArtPM3D
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////
//                                                                //
//                                                                //
//                                                                //
//                                                                //
//                                                                //
//          db                 mm   `7MM"""Mq.`7MMM.     ,MMF'    //
//         ;MM:                MM     MM   `MM. MMMb    dPMM      //
//        ,V^MM.    `7Mb,od8 mmMMmm   MM   ,M9  M YM   ,M MM      //
//       ,M  `MM      MM' "'   MM     MMmmdM9   M  Mb  M' MM      //
//       AbmmmqMA     MM       MM     MM        M  YM.P'  MM      //
//      A'     VML    MM       MM     MM        M  `YM'   MM      //
//    .AMA.   .AMMA..JMML.     `Mbmo.JMML.    .JML. `'  .JMML.    //
//                                                                //
//                                                                //
//                                                                //
//                                                                //
//                                                                //
////////////////////////////////////////////////////////////////////


contract ArtPM is ERC721Creator {
    constructor() ERC721Creator("TheArtPM3D", "ArtPM") {}
}