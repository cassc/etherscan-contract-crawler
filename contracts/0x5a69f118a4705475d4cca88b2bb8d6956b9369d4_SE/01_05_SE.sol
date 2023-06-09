// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Special Editions
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////
//                        //
//                        //
//    Special Editions    //
//    JKTLM,              //
//    June, 2023          //
//                        //
//                        //
////////////////////////////


contract SE is ERC721Creator {
    constructor() ERC721Creator("Special Editions", "SE") {}
}