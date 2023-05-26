// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: plutonic mind
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
//                 ,,                                              ,,                                   ,,                     ,,      //
//               `7MM                mm                            db                                   db                   `7MM      //
//                 MM                MM                                                                                        MM      //
//    `7MMpdMAo.   MM  `7MM  `7MM  mmMMmm   ,pW"Wq.  `7MMpMMMb.  `7MM   ,p6"bo      `7MMpMMMb.pMMMb.  `7MM  `7MMpMMMb.    ,M""bMM      //
//      MM   `Wb   MM    MM    MM    MM    6W'   `Wb   MM    MM    MM  6M'  OO        MM    MM    MM    MM    MM    MM  ,AP    MM      //
//      MM    M8   MM    MM    MM    MM    8M     M8   MM    MM    MM  8M             MM    MM    MM    MM    MM    MM  8MI    MM      //
//      MM   ,AP   MM    MM    MM    MM    YA.   ,A9   MM    MM    MM  YM.    ,       MM    MM    MM    MM    MM    MM  `Mb    MM      //
//      MMbmmd'  .JMML.  `Mbod"YML.  `Mbmo  `Ybmd9'  .JMML  JMML..JMML. YMbmd'      .JMML  JMML  JMML..JMML..JMML  JMML. `Wbmd"MML.    //
//      MM                                                                                                                             //
//    .JMML.                                                                                                                           //
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract pm is ERC721Creator {
    constructor() ERC721Creator("plutonic mind", "pm") {}
}