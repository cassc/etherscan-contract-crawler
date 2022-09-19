// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: metempsychosis
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                               //
//                                                                                                                                               //
//                                                                                                                                               //
//                                                                                                                                               //
//                                                                                                  ,,                           ,,              //
//                               mm                                                               `7MM                           db              //
//                               MM                                                                 MM                                           //
//    `7MMpMMMb.pMMMb.  .gP"Ya mmMMmm .gP"Ya `7MMpMMMb.pMMMb. `7MMpdMAo. ,pP"Ybd `7M'   `MF',p6"bo  MMpMMMb.  ,pW"Wq.  ,pP"Ybd `7MM  ,pP"Ybd     //
//      MM    MM    MM ,M'   Yb  MM  ,M'   Yb  MM    MM    MM   MM   `Wb 8I   `"   VA   ,V 6M'  OO  MM    MM 6W'   `Wb 8I   `"   MM  8I   `"     //
//      MM    MM    MM 8M""""""  MM  8M""""""  MM    MM    MM   MM    M8 `YMMMa.    VA ,V  8M       MM    MM 8M     M8 `YMMMa.   MM  `YMMMa.     //
//      MM    MM    MM YM.    ,  MM  YM.    ,  MM    MM    MM   MM   ,AP L.   I8     VVV   YM.    , MM    MM YA.   ,A9 L.   I8   MM  L.   I8     //
//    .JMML  JMML  JMML.`Mbmmd'  `Mbmo`Mbmmd'.JMML  JMML  JMML. MMbmmd'  M9mmmP'     ,V     YMbmd'.JMML  JMML.`Ybmd9'  M9mmmP' .JMML.M9mmmP'     //
//                                                              MM                  ,V                                                           //
//                                                            .JMML.             OOb"                                                            //
//                                                                                                                                               //
//                                                                                                                                               //
//                                                                                                                                               //
//                                                                                                                                               //
//                                                                                                                                               //
//                                                                                                                                               //
//                                                                                                                                               //
//                                                                                                                                               //
//                                                                                                                                               //
//                                                                                                                                               //
//                                                                                                                                               //
//                                                                                                                                               //
//                                                                                                                                               //
//                                                                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MP is ERC721Creator {
    constructor() ERC721Creator("metempsychosis", "MP") {}
}