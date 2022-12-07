// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: for once.
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//                                                                          //
//                                                                          //
//        ,...                                                              //
//      .d' ""                                                              //
//      dM`                                                                 //
//     mMMmm,pW"Wq.`7Mb,od8      ,pW"Wq.`7MMpMMMb.  ,p6"bo   .gP"Ya         //
//      MM 6W'   `Wb MM' "'     6W'   `Wb MM    MM 6M'  OO  ,M'   Yb        //
//      MM 8M     M8 MM         8M     M8 MM    MM 8M       8M""""""        //
//      MM YA.   ,A9 MM         YA.   ,A9 MM    MM YM.    , YM.    , ,,     //
//    .JMML.`Ybmd9'.JMML.        `Ybmd9'.JMML  JMML.YMbmd'   `Mbmmd' db     //
//                                                                          //
//                                                                          //
//                                                                          //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////


contract fo is ERC1155Creator {
    constructor() ERC1155Creator("for once.", "fo") {}
}