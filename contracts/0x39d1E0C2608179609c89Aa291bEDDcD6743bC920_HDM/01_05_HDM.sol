// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: HELIUS.DIGITAL
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////
//                          //
//                          //
//    //////////////////    //
//    //              //    //
//    //              //    //
//    //    helius    //    //
//    //              //    //
//    //              //    //
//    //////////////////    //
//    Copyright © 2023      //
//                          //
//                          //
//                          //
//                          //
//////////////////////////////


contract HDM is ERC721Creator {
    constructor() ERC721Creator("HELIUS.DIGITAL", "HDM") {}
}