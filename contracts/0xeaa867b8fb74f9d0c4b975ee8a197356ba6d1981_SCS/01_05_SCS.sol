// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Simon's Christmas Special
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                              //
//                                                                                                                              //
//                                                                                                                              //
//                                                                                                                              //
//                                                                                                                              //
//     .M"""bgd `7MMF'`7MMM.     ,MMF' .g8""8q. `7MN.   `7MF'     db      `7MMF'  `7MMF'`7MMF'   `7MF'`7MM"""YMM   .M"""bgd     //
//    ,MI    "Y   MM    MMMb    dPMM .dP'    `YM. MMN.    M      ;MM:       MM      MM    MM       M    MM    `7  ,MI    "Y     //
//    `MMb.       MM    M YM   ,M MM dM'      `MM M YMb   M     ,V^MM.      MM      MM    MM       M    MM   d    `MMb.         //
//      `YMMNq.   MM    M  Mb  M' MM MM        MM M  `MN. M    ,M  `MM      MMmmmmmmMM    MM       M    MMmmMM      `YMMNq.     //
//    .     `MM   MM    M  YM.P'  MM MM.      ,MP M   `MM.M    AbmmmqMA     MM      MM    MM       M    MM   Y  , .     `MM     //
//    Mb     dM   MM    M  `YM'   MM `Mb.    ,dP' M     YMM   A'     VML    MM      MM    YM.     ,M    MM     ,M Mb     dM     //
//    P"Ybmmd"  .JMML..JML. `'  .JMML. `"bmmd"' .JML.    YM .AMA.   .AMMA..JMML.  .JMML.   `bmmmmd"'  .JMMmmmmMMM P"Ybmmd"      //
//                                                                                                                              //
//                                                                                                                              //
//                                                                                                                              //
//                                                                                                                              //
//                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SCS is ERC1155Creator {
    constructor() ERC1155Creator("Simon's Christmas Special", "SCS") {}
}