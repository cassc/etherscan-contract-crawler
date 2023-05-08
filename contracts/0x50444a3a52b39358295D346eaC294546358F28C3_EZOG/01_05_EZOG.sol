// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: EZ.OG
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////
//                        //
//                        //
//    ////////////////    //
//    //            //    //
//    //            //    //
//    //    EASY    //    //
//    //    EASY    //    //
//    //    EASY    //    //
//    //            //    //
//    //            //    //
//    ////////////////    //
//                        //
//                        //
////////////////////////////


contract EZOG is ERC1155Creator {
    constructor() ERC1155Creator("EZ.OG", "EZOG") {}
}