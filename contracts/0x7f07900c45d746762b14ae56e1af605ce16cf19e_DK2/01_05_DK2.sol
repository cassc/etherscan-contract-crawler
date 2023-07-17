// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DK Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//                                                                          //
//                                                                          //
//                                                                          //
//                       ,,   ,,          ,,                                //
//    `7MM"""YMM       `7MM   db   mm     db                                //
//      MM    `7         MM        MM                                       //
//      MM   d      ,M""bMM `7MM mmMMmm `7MM  ,pW"Wq.`7MMpMMMb. ,pP"Ybd     //
//      MMmmMM    ,AP    MM   MM   MM     MM 6W'   `Wb MM    MM 8I   `"     //
//      MM   Y  , 8MI    MM   MM   MM     MM 8M     M8 MM    MM `YMMMa.     //
//      MM     ,M `Mb    MM   MM   MM     MM YA.   ,A9 MM    MM L.   I8     //
//    .JMMmmmmMMM  `Wbmd"MML.JMML. `Mbmo.JMML.`Ybmd9'.JMML  JMMLM9mmmP'     //
//     ,,                                                                   //
//    *MM                     `7MM"""Yb. `7MMF' `YMM'                       //
//     MM                       MM    `Yb. MM   .M'                         //
//     MM,dMMb.`7M'   `MF'      MM     `Mb MM .d"                           //
//     MM    `Mb VA   ,V        MM      MM MMMMM.                           //
//     MM     M8  VA ,V         MM     ,MP MM  VMA                          //
//     MM.   ,M9   VVV          MM    ,dP' MM   `MM.                        //
//     P^YbmdP'    ,V         .JMMmmmdP' .JMML.   MMb.                      //
//                ,V                                                        //
//             OOb"                                                         //
//                                                                          //
//                                                                          //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////


contract DK2 is ERC1155Creator {
    constructor() ERC1155Creator("DK Editions", "DK2") {}
}