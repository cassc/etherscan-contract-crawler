// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PIXELS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                  //
//                                                                                                                                  //
//                                                                                                                                  //
//                                                                                                                                  //
//    `7MM"""Mq.`7MMF'`YMM'   `MP' `7MM"""YMM  `7MMF'       .M"""bgd                                                                //
//      MM   `MM. MM    VMb.  ,P     MM    `7    MM        ,MI    "Y                                                                //
//      MM   ,M9  MM     `MM.M'      MM   d      MM        `MMb.                                                                    //
//      MMmmdM9   MM       MMb       MMmmMM      MM          `YMMNq.                                                                //
//      MM        MM     ,M'`Mb.     MM   Y  ,   MM      , .     `MM                                                                //
//      MM        MM    ,P   `MM.    MM     ,M   MM     ,M Mb     dM                                                                //
//    .JMML.    .JMML..MM:.  .:MMa..JMMmmmmMMM .JMMmmmmMMM P"Ybmmd"                                                                 //
//                                                                                                                                  //
//                                                                                                                                  //
//                                                                                                                                  //
//     ,,                                                                                                                           //
//    *MM                                                                                                                           //
//     MM                                                                                                                           //
//     MM,dMMb.`7M'   `MF'                                                                                                          //
//     MM    `Mb VA   ,V                                                                                                            //
//     MM     M8  VA ,V                                                                                                             //
//     MM.   ,M9   VVV                                                                                                              //
//     P^YbmdP'    ,V                                                                                                               //
//                ,V                                                                                                                //
//             OOb"                                                                                                                 //
//                                                                                                                                  //
//                                                                                                                                  //
//      .g8"""bgd     db      `7MM"""Mq.   .M"""bgd   .g8""8q. `7MN.   `7MF'     db   MMP""MM""YMM `7MM"""YMM  `7MM"""Yb.           //
//    .dP'     `M    ;MM:       MM   `MM. ,MI    "Y .dP'    `YM. MMN.    M      ;MM:  P'   MM   `7   MM    `7    MM    `Yb.         //
//    dM'       `   ,V^MM.      MM   ,M9  `MMb.     dM'      `MM M YMb   M     ,V^MM.      MM        MM   d      MM     `Mb         //
//    MM           ,M  `MM      MMmmdM9     `YMMNq. MM        MM M  `MN. M    ,M  `MM      MM        MMmmMM      MM      MM         //
//    MM.          AbmmmqMA     MM  YM.   .     `MM MM.      ,MP M   `MM.M    AbmmmqMA     MM        MM   Y  ,   MM     ,MP         //
//    `Mb.     ,' A'     VML    MM   `Mb. Mb     dM `Mb.    ,dP' M     YMM   A'     VML    MM        MM     ,M   MM    ,dP'         //
//      `"bmmmd'.AMA.   .AMMA..JMML. .JMM.P"Ybmmd"    `"bmmd"' .JML.    YM .AMA.   .AMMA..JMML.    .JMMmmmmMMM .JMMmmmdP'           //
//                                                                                                                                  //
//                                                                                                                                  //
//                                                                                                                                  //
//                                                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PIXLS is ERC1155Creator {
    constructor() ERC1155Creator("PIXELS", "PIXLS") {}
}