// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Spirxl
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////
//                        //
//                        //
//    ////////////////    //
//    //            //    //
//    //            //    //
//    //    MXKE    //    //
//    //            //    //
//    //            //    //
//    ////////////////    //
//                        //
//                        //
////////////////////////////


contract SPIRXL is ERC1155Creator {
    constructor() ERC1155Creator("The Spirxl", "SPIRXL") {}
}