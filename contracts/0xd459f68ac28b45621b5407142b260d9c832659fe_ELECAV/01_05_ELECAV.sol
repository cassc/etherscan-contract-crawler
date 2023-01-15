// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ELECTRIC AVENUE
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                             //
//                                                                                                                                                             //
//                                                                                                                                                             //
//                                                                                                                                                             //
//                                                                                                                                                             //
//    __________ ____     __________   ____   __________ ________   ____   ____                _  ____     ___ __________ ___      ______     ____________     //
//    `MMMMMMMMM `MM'     `MMMMMMMMM  6MMMMb/ MMMMMMMMMM `MMMMMMMb. `MM'  6MMMMb/             dM. `Mb(     )d' `MMMMMMMMM `MM\     `M`MM'     `M`MMMMMMMMM     //
//     MM      \  MM       MM      \ 8P    YM /   MM   \  MM    `Mb  MM  8P    YM            ,MMb  YM.     ,P   MM      \  MMM\     M MM       M MM      \     //
//     MM         MM       MM       6M      Y     MM      MM     MM  MM 6M      Y            d'YM. `Mb     d'   MM         M\MM\    M MM       M MM            //
//     MM    ,    MM       MM    ,  MM            MM      MM     MM  MM MM                  ,P `Mb  YM.   ,P    MM    ,    M \MM\   M MM       M MM    ,       //
//     MMMMMMM    MM       MMMMMMM  MM            MM      MM    .M9  MM MM                  d'  YM. `Mb   d'    MMMMMMM    M  \MM\  M MM       M MMMMMMM       //
//     MM    `    MM       MM    `  MM            MM      MMMMMMM9'  MM MM                 ,P   `Mb  YM. ,P     MM    `    M   \MM\ M MM       M MM    `       //
//     MM         MM       MM       MM            MM      MM  \M\    MM MM                 d'    YM. `Mb d'     MM         M    \MM\M MM       M MM            //
//     MM         MM       MM       YM      6     MM      MM   \M\   MM YM      6         ,MMMMMMMMb  YM,P      MM         M     \MMM YM       M MM            //
//     MM      /  MM    /  MM      / 8b    d9     MM      MM    \M\  MM  8b    d9         d'      YM. `MM'      MM      /  M      \MM  8b     d8 MM      /     //
//    _MMMMMMMMM _MMMMMMM _MMMMMMMMM  YMMMM9     _MM_    _MM_    \M\_MM_  YMMMM9        _dM_     _dMM_ YP      _MMMMMMMMM _M_      \M   YMMMMM9 _MMMMMMMMM     //
//                                                                                                                                                             //
//                                                                                                                                                             //
//                                                                                                                                                             //
//                                                                                                                                                             //
//                                                                                                                                                             //
//                                                                                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ELECAV is ERC1155Creator {
    constructor() ERC1155Creator("ELECTRIC AVENUE", "ELECAV") {}
}