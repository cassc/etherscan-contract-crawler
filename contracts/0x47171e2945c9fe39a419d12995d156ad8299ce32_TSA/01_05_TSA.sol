// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: the senior apartment
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                //
//                                                                                                //
//    eyes on time, dressed and went to the bathroom to look at a familiar face in the mirror.    //
//                                                                                                //
//                                                                                                //
//                                                                                                //
//    Ai Liang, 14 years old, is now a middle school student.                                     //
//                                                                                                //
//                                                                                                //
//                                                                                                //
//    This is his new identity after the trip.                                                    //
//                                                                                                //
//                                                                                                //
//                                                                                                //
//                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////


contract TSA is ERC721Creator {
    constructor() ERC721Creator("the senior apartment", "TSA") {}
}