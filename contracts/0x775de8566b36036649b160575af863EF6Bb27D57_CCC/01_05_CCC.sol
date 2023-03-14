// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Cool Checks Club
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                             //
//                                                                                                                                             //
//                                                                                                                                             //
//                                                                                                                                             //
//                                                                                                                                             //
//       ____                      ___          ____   ___                        ___                        ____   ___          ___           //
//      6MMMMb/                    `MM         6MMMMb/ `MM                        `MM                       6MMMMb/ `MM           MM           //
//     8P    YM                     MM        8P    YM  MM                         MM                      8P    YM  MM           MM           //
//    6M      Y   _____     _____   MM       6M      Y  MM  __     ____     ____   MM   __   ____         6M      Y  MM ___   ___ MM____       //
//    MM         6MMMMMb   6MMMMMb  MM       MM         MM 6MMb   6MMMMb   6MMMMb. MM   d'  6MMMMb\       MM         MM `MM    MM MMMMMMb      //
//    MM        6M'   `Mb 6M'   `Mb MM       MM         MMM9 `Mb 6M'  `Mb 6M'   Mb MM  d'  MM'    `       MM         MM  MM    MM MM'  `Mb     //
//    MM        MM     MM MM     MM MM       MM         MM'   MM MM    MM MM    `' MM d'   YM.            MM         MM  MM    MM MM    MM     //
//    MM        MM     MM MM     MM MM       MM         MM    MM MMMMMMMM MM       MMdM.    YMMMMb        MM         MM  MM    MM MM    MM     //
//    YM      6 MM     MM MM     MM MM       YM      6  MM    MM MM       MM       MMPYM.       `Mb       YM      6  MM  MM    MM MM    MM     //
//     8b    d9 YM.   ,M9 YM.   ,M9 MM        8b    d9  MM    MM YM    d9 YM.   d9 MM  YM. L    ,MM        8b    d9  MM  YM.   MM MM.  ,M9     //
//      YMMMM9   YMMMMM9   YMMMMM9 _MM_        YMMMM9  _MM_  _MM_ YMMMM9   YMMMM9 _MM_  YM.MYMMMM9          YMMMM9  _MM_  YMMM9MM_MYMMMM9      //
//                                                                                                                                             //
//                                                                                                                                             //
//                                                                                                                                             //
//                                                                                                                                             //
//                                                                                                                                             //
//                                                                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CCC is ERC1155Creator {
    constructor() ERC1155Creator("Cool Checks Club", "CCC") {}
}