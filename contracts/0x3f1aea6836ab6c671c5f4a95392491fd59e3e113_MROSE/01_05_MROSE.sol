// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MysticRose
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                               //
//                                                                                                               //
//    ///////////////////////////////////////////////////////////////////////////////////////////////////////    //
//    //                                                                                                   //    //
//    //                                                                                                   //    //
//    //                                                                                                   //    //
//    //                                                                                                   //    //
//    //                                               ,,                                                  //    //
//    //    `7MMM.     ,MMF'                    mm     db        `7MM"""Mq.                                //    //
//    //      MMMb    dPMM                      MM                 MM   `MM.                               //    //
//    //      M YM   ,M MM `7M'   `MF',pP"Ybd mmMMmm `7MM  ,p6"bo  MM   ,M9  ,pW"Wq.  ,pP"Ybd  .gP"Ya      //    //
//    //      M  Mb  M' MM   VA   ,V  8I   `"   MM     MM 6M'  OO  MMmmdM9  6W'   `Wb 8I   `" ,M'   Yb     //    //
//    //      M  YM.P'  MM    VA ,V   `YMMMa.   MM     MM 8M       MM  YM.  8M     M8 `YMMMa. 8M""""""     //    //
//    //      M  `YM'   MM     VVV    L.   I8   MM     MM YM.    , MM   `Mb.YA.   ,A9 L.   I8 YM.    ,     //    //
//    //    .JML. `'  .JMML.   ,V     M9mmmP'   `Mbmo.JMML.YMbmd'.JMML. .JMM.`Ybmd9'  M9mmmP'  `Mbmmd'     //    //
//    //                      ,V                                                                           //    //
//    //                   OOb"                                                                            //    //
//    //                                                                                                   //    //
//    //                                                                                                   //    //
//    //                                                                                                   //    //
//    //                                                                                                   //    //
//    ///////////////////////////////////////////////////////////////////////////////////////////////////////    //
//                                                                                                               //
//                                                                                                               //
//                                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MROSE is ERC721Creator {
    constructor() ERC721Creator("MysticRose", "MROSE") {}
}