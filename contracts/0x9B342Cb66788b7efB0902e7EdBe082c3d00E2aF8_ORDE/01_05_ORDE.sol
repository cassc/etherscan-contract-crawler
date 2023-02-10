// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bitcoin Ordinal Elilustrador
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                             //
//                                                                                                                                                                                                                             //
//                                                                                                                                                                                                                             //
//                                                                                                                                                                                                                             //
//    ________                                                       ____                 ___                        ___       __________ ___     ___                                                 ___                      //
//    `MMMMMMMb. 68b                          68b                   6MMMMb                `MM 68b                    `MM       `MMMMMMMMM `MM 68b `MM                                                 `MM                      //
//     MM    `Mb Y89   /                      Y89                  8P    Y8                MM Y89                     MM        MM      \  MM Y89  MM                     /                            MM                      //
//     MM     MM ___  /M      ____     _____  ___ ___  __         6M      Mb ___  __   ____MM ___ ___  __      ___    MM        MM         MM ___  MM ___   ___   ____   /M     ___  __    ___     ____MM   _____  ___  __     //
//     MM    .M9 `MM /MMMMM  6MMMMb.  6MMMMMb `MM `MM 6MMb        MM      MM `MM 6MM  6MMMMMM `MM `MM 6MMb   6MMMMb   MM        MM    ,    MM `MM  MM `MM    MM  6MMMMb\/MMMMM  `MM 6MM  6MMMMb   6MMMMMM  6MMMMMb `MM 6MM     //
//     MMMMMMM(   MM  MM    6M'   Mb 6M'   `Mb MM  MMM9 `Mb       MM      MM  MM69 " 6M'  `MM  MM  MMM9 `Mb 8M'  `Mb  MM        MMMMMMM    MM  MM  MM  MM    MM MM'    ` MM      MM69 " 8M'  `Mb 6M'  `MM 6M'   `Mb MM69 "     //
//     MM    `Mb  MM  MM    MM    `' MM     MM MM  MM'   MM       MM      MM  MM'    MM    MM  MM  MM'   MM     ,oMM  MM        MM    `    MM  MM  MM  MM    MM YM.      MM      MM'        ,oMM MM    MM MM     MM MM'        //
//     MM     MM  MM  MM    MM       MM     MM MM  MM    MM       MM      MM  MM     MM    MM  MM  MM    MM ,6MM9'MM  MM        MM         MM  MM  MM  MM    MM  YMMMMb  MM      MM     ,6MM9'MM MM    MM MM     MM MM         //
//     MM     MM  MM  MM    MM       MM     MM MM  MM    MM       YM      M9  MM     MM    MM  MM  MM    MM MM'   MM  MM        MM         MM  MM  MM  MM    MM      `Mb MM      MM     MM'   MM MM    MM MM     MM MM         //
//     MM    .M9  MM  YM.  ,YM.   d9 YM.   ,M9 MM  MM    MM        8b    d8   MM     YM.  ,MM  MM  MM    MM MM.  ,MM  MM        MM      /  MM  MM  MM  YM.   MM L    ,MM YM.  ,  MM     MM.  ,MM YM.  ,MM YM.   ,M9 MM         //
//    _MMMMMMM9' _MM_  YMMM9 YMMMM9   YMMMMM9 _MM__MM_  _MM_        YMMMM9   _MM_     YMMMMMM__MM__MM_  _MM_`YMMM9'Yb_MM_      _MMMMMMMMM _MM__MM__MM_  YMMM9MM_MYMMMM9   YMMM9 _MM_    `YMMM9'Yb.YMMMMMM_ YMMMMM9 _MM_        //
//                                                                                                                                                                                                                             //
//                                                                                                                                                                                                                             //
//                                                                                                                                                                                                                             //
//                                                                                                                                                                                                                             //
//                                                                                                                                                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ORDE is ERC721Creator {
    constructor() ERC721Creator("Bitcoin Ordinal Elilustrador", "ORDE") {}
}