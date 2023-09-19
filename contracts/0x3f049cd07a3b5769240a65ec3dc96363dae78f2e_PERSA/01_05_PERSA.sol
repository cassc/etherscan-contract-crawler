// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PERSA
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////
//                                                                 //
//                                                                 //
//    `7MM"""Mq.`7MM"""YMM  `7MM"""Mq.   .M"""bgd      db          //
//      MM   `MM. MM    `7    MM   `MM. ,MI    "Y     ;MM:         //
//      MM   ,M9  MM   d      MM   ,M9  `MMb.        ,V^MM.        //
//      MMmmdM9   MMmmMM      MMmmdM9     `YMMNq.   ,M  `MM        //
//      MM        MM   Y  ,   MM  YM.   .     `MM   AbmmmqMA       //
//      MM        MM     ,M   MM   `Mb. Mb     dM  A'     VML      //
//    .JMML.    .JMMmmmmMMM .JMML. .JMM.P"Ybmmd" .AMA.   .AMMA.    //
//                                                                 //
//                                                                 //
//                          SensualBody                            //
//                                                                 //
//                                                                 //
/////////////////////////////////////////////////////////////////////


contract PERSA is ERC721Creator {
    constructor() ERC721Creator("PERSA", "PERSA") {}
}