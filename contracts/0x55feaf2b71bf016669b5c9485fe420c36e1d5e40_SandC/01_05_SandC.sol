// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Strenght & Class
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                               //
//                                                                                                                                               //
//      ____                                               ___                       __                ____   ___                                //
//     6MMMMb\                                             `MM                      6MMb              6MMMMb/ `MM                                //
//    6M'    `   /                                          MM         /           6M' `b            8P    YM  MM                                //
//    MM        /M     ___  __   ____   ___  __     __      MM  __    /M           8M  ,9           6M      Y  MM    ___      ____     ____      //
//    YM.      /MMMMM  `MM 6MM  6MMMMb  `MM 6MMb   6MMbMMM  MM 6MMb  /MMMMM        YM.,9  ___       MM         MM  6MMMMb    6MMMMb\  6MMMMb\    //
//     YMMMMb   MM      MM69 " 6M'  `Mb  MMM9 `Mb 6M'`Mb    MMM9 `Mb  MM            `Mb   `M'       MM         MM 8M'  `Mb  MM'    ` MM'    `    //
//         `Mb  MM      MM'    MM    MM  MM'   MM MM  MM    MM'   MM  MM           ,M'MM   P        MM         MM     ,oMM  YM.      YM.         //
//          MM  MM      MM     MMMMMMMM  MM    MM YM.,M9    MM    MM  MM           MM  YM. 7        MM         MM ,6MM9'MM   YMMMMb   YMMMMb     //
//          MM  MM      MM     MM        MM    MM  YMM9     MM    MM  MM           MM   `Mb         YM      6  MM MM'   MM       `Mb      `Mb    //
//    L    ,M9  YM.  ,  MM     YM    d9  MM    MM (M        MM    MM  YM.  ,       YM.   7MM         8b    d9  MM MM.  ,MM  L    ,MM L    ,MM    //
//    MYMMMM9    YMMM9 _MM_     YMMMM9  _MM_  _MM_ YMMMMb. _MM_  _MM_  YMMM9        YMMM9  YM_        YMMMM9  _MM_`YMMM9'Yb.MYMMMM9  MYMMMM9     //
//                                                6M    Yb                                                                                       //
//                                                YM.   d9                                                                                       //
//                                                 YMMMM9                                                                                        //
//                                                                                                                                               //
//                                                                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SandC is ERC721Creator {
    constructor() ERC721Creator("Strenght & Class", "SandC") {}
}