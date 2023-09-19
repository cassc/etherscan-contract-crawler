// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Do You Want To Feel Something?
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                 //
//                                                                                                                                                                 //
//                                                                                                                                                                 //
//                                                                                                                                                                 //
//    `7MM"""Yb.                 `YMM'   `MM'                     `7MMF'     A     `7MF'                  mm                                                       //
//      MM    `Yb.                 VMA   ,V                         `MA     ,MA     ,V                    MM                                                       //
//      MM     `Mb  ,pW"Wq.         VMA ,V ,pW"Wq.`7MM  `7MM         VM:   ,VVM:   ,V ,6"Yb.  `7MMpMMMb.mmMMmm                                                     //
//      MM      MM 6W'   `Wb         VMMP 6W'   `Wb MM    MM          MM.  M' MM.  M'8)   MM    MM    MM  MM                                                       //
//      MM     ,MP 8M     M8          MM  8M     M8 MM    MM          `MM A'  `MM A'  ,pm9MM    MM    MM  MM                                                       //
//      MM    ,dP' YA.   ,A9          MM  YA.   ,A9 MM    MM           :MM;    :MM;  8M   MM    MM    MM  MM                                                       //
//    .JMMmmmdP'    `Ybmd9'         .JMML. `Ybmd9'  `Mbod"YML.          VF      VF   `Moo9^Yo..JMML  JMML.`Mbmo                                                    //
//                                                                                                                                                                 //
//                                                                                                                                                                 //
//                                                                                                                                                                 //
//                                                      ,,                                                          ,,          ,,                                 //
//    MMP""MM""YMM          `7MM"""YMM                `7MM       .M"""bgd                                    mm   `7MM          db                    ,M"""b.      //
//    P'   MM   `7            MM    `7                  MM      ,MI    "Y                                    MM     MM                                89'  `Mg     //
//         MM  ,pW"Wq.        MM   d  .gP"Ya   .gP"Ya   MM      `MMb.      ,pW"Wq.`7MMpMMMb.pMMMb.  .gP"Ya mmMMmm   MMpMMMb.  `7MM  `7MMpMMMb.  .P"Ybmmm   ,M9     //
//         MM 6W'   `Wb       MM""MM ,M'   Yb ,M'   Yb  MM        `YMMNq. 6W'   `Wb MM    MM    MM ,M'   Yb  MM     MM    MM    MM    MM    MM :MI  I8  mMMY'      //
//         MM 8M     M8       MM   Y 8M"""""" 8M""""""  MM      .     `MM 8M     M8 MM    MM    MM 8M""""""  MM     MM    MM    MM    MM    MM  WmmmP"  MM         //
//         MM YA.   ,A9       MM     YM.    , YM.    ,  MM      Mb     dM YA.   ,A9 MM    MM    MM YM.    ,  MM     MM    MM    MM    MM    MM 8M       ,,         //
//       .JMML.`Ybmd9'      .JMML.    `Mbmmd'  `Mbmmd'.JMML.    P"Ybmmd"   `Ybmd9'.JMML  JMML  JMML.`Mbmmd'  `Mbmo.JMML  JMML..JMML..JMML  JMML.YMMMMMb db         //
//                                                                                                                                             6'     dP           //
//                                                                                                                                             Ybmmmd'             //
//                                                                                                                                                                 //
//                                                                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract DYWTFS is ERC1155Creator {
    constructor() ERC1155Creator("Do You Want To Feel Something?", "DYWTFS") {}
}