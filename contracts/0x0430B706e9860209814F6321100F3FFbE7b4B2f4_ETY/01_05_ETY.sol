// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ethernity
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                  //
//                                                                                                                  //
//                                                                                                                  //
//                                                                                                                  //
//    `7MM"""YMM MMP""MM""YMM `7MMF'  `7MMF'`7MM"""YMM  `7MM"""Mq.  `7MN.   `7MF'`7MMF'MMP""MM""YMM `YMM'   `MM'    //
//      MM    `7 P'   MM   `7   MM      MM    MM    `7    MM   `MM.   MMN.    M    MM  P'   MM   `7   VMA   ,V      //
//      MM   d        MM        MM      MM    MM   d      MM   ,M9    M YMb   M    MM       MM         VMA ,V       //
//      MMmmMM        MM        MMmmmmmmMM    MMmmMM      MMmmdM9     M  `MN. M    MM       MM          VMMP        //
//      MM   Y  ,     MM        MM      MM    MM   Y  ,   MM  YM.     M   `MM.M    MM       MM           MM         //
//      MM     ,M     MM        MM      MM    MM     ,M   MM   `Mb.   M     YMM    MM       MM           MM         //
//    .JMMmmmmMMM   .JMML.    .JMML.  .JMML..JMMmmmmMMM .JMML. .JMM..JML.    YM  .JMML.   .JMML.       .JMML.       //
//                                                                                                                  //
//                                                                                                                  //
//                                                                                                                  //
//                                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ETY is ERC721Creator {
    constructor() ERC721Creator("Ethernity", "ETY") {}
}