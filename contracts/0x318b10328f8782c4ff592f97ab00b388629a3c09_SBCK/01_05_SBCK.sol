// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SuperBorn (ck)
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                      //
//                                                                                                                                                                                                                      //
//                                                                                                                                                                                                                      //
//                                                                                                                                                                                                                      //
//            ____     ___                         ________                   ___      ___        ,'  ____   ___    __`.                         __  __                         ___                                     //
//            `MM'     `M'                         `MMMMMMMb.                 `MM\     `M'       6P  6MMMMb/ `MM    d'  Yb                       69MM69M68b         68b          `MM                                    //
//             MM       M                           MM    `Mb                  MMM\     M       ,M' 8P    YM  MM   d'  `M.                     6M' 6M' Y89         Y89           MM                          /          //
//      ____   MM       M __ ____     ____  ___  __ MM     MM   _____  ___  __ M\MM\    M       MM 6M      Y  MM  d'    MM             _____  _MM__MM_____   ____  ___    ___    MM          ___   ___  __  /M          //
//     6MMMMb\ MM       M `M6MMMMb   6MMMMb `MM 6MM MM    .M9  6MMMMMb `MM 6MM M \MM\   M       MM MM         MM d'     MM 68b        6MMMMMb MMMMMMMMM`MM  6MMMMb.`MM  6MMMMb   MM        6MMMMb  `MM 6MM /MMMMM       //
//    MM'    ` MM       M  MM'  `Mb 6M'  `Mb MM69 " MMMMMMM(  6M'   `Mb MM69 " M  \MM\  M       MM MM         MMd'      MM Y89       6M'   `Mb MM  MM   MM 6M'   Mb MM 8M'  `Mb  MM       8M'  `Mb  MM69 "  MM          //
//    YM.      MM       M  MM    MM MM    MM MM'    MM    `Mb MM     MM MM'    M   \MM\ M       MM MM         MMYM.     MM           MM     MM MM  MM   MM MM    `' MM     ,oMM  MM           ,oMM  MM'     MM          //
//     YMMMMb  MM       M  MM    MM MMMMMMMM MM     MM     MM MM     MM MM     M    \MM\M       MM MM         MM YM.    MM           MM     MM MM  MM   MM MM       MM ,6MM9'MM  MM       ,6MM9'MM  MM      MM          //
//         `Mb YM       M  MM    MM MM       MM     MM     MM MM     MM MM     M     \MMM       MM YM      6  MM  YM.   MM           MM     MM MM  MM   MM MM       MM MM'   MM  MM       MM'   MM  MM      MM          //
//    L    ,MM  8b     d8  MM.  ,M9 YM    d9 MM     MM    .M9 YM.   ,M9 MM     M      \MM       MM  8b    d9  MM   YM.  MM 68b       YM.   ,M9 MM  MM   MM YM.   d9 MM MM.  ,MM  MM       MM.  ,MM  MM      YM.  ,      //
//    MYMMMM9    YMMMMM9   MMYMMM9   YMMMM9 _MM_   _MMMMMMM9'  YMMMMM9 _MM_   _M_      \M       MM   YMMMM9  _MM_   YM._MM Y89        YMMMMM9 _MM__MM_ _MM_ YMMMM9 _MM_`YMMM9'Yb_MM_      `YMMM9'Yb_MM_      YMMM9      //
//                         MM                                                                   `M.                    ,M'                                                                                              //
//                         MM                                                                    Yb                    d9                                                                                               //
//                        _MM_                                                                    `.                  ,'                                                                                                //
//                                                                                                                                                                                                                      //
//                                                                                                                                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SBCK is ERC1155Creator {
    constructor() ERC1155Creator("SuperBorn (ck)", "SBCK") {}
}