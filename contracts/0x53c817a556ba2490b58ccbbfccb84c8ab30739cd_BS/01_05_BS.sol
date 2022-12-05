// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Beauty Sweets
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    Concept: Photo shot for Beauty Sweets Makeup Brand                                                                          //
//                                                                                                                                //
//    Model: Violet                                                                                                               //
//                                                                                                                                //
//    " Such a dreamy place, everything is huge and sparkling, the sweet smell of beauty products is covering the atmosphere "    //
//                                                                                                                                //
//                                                                                                                                //
//    Do you love makeup? Do you love pastel colors? Do you want to push you're cuteness?                                         //
//                                                                                                                                //
//     Here are our cute and colorful products for you                                                                            //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BS is ERC1155Creator {
    constructor() ERC1155Creator("Beauty Sweets", "BS") {}
}