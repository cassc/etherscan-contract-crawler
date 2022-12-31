// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mind Control
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                           //
//                                                                                                                                                           //
//                                                                                                                                                           //
//                                                                                                                                                           //
//                                                                                                                                                           //
//    `7MMM.     ,MMF'    `7MMF'    `7MN.   `7MF'    `7MM"""Yb.         .g8"""bgd   .g8""8q. `7MN.   `7MF'MMP""MM""YMM `7MM"""Mq.   .g8""8q. `7MMF'          //
//      MMMb    dPMM        MM        MMN.    M        MM    `Yb.     .dP'     `M .dP'    `YM. MMN.    M  P'   MM   `7   MM   `MM..dP'    `YM. MM            //
//      M YM   ,M MM        MM        M YMb   M        MM     `Mb     dM'       ` dM'      `MM M YMb   M       MM        MM   ,M9 dM'      `MM MM            //
//      M  Mb  M' MM        MM        M  `MN. M        MM      MM     MM          MM        MM M  `MN. M       MM        MMmmdM9  MM        MM MM            //
//      M  YM.P'  MM        MM        M   `MM.M        MM     ,MP     MM.         MM.      ,MP M   `MM.M       MM        MM  YM.  MM.      ,MP MM      ,     //
//      M  `YM'   MM        MM        M     YMM        MM    ,dP'     `Mb.     ,' `Mb.    ,dP' M     YMM       MM        MM   `Mb.`Mb.    ,dP' MM     ,M     //
//    .JML. `'  .JMML.    .JMML.    .JML.    YM      .JMMmmmdP'         `"bmmmd'    `"bmmd"' .JML.    YM     .JMML.    .JMML. .JMM. `"bmmd"' .JMMmmmmMMM     //
//                                                                                                                                                           //
//                                                                                                                                                           //
//                                                                                                                                                           //
//                                                                                                                                                           //
//                                                                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MELT is ERC721Creator {
    constructor() ERC721Creator("Mind Control", "MELT") {}
}