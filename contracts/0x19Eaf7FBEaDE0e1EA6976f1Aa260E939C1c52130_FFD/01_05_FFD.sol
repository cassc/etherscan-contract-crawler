// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FOOD FOR DEGENS
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////
//                //
//                //
//    ////FOOD    //
//    ////////    //
//    /////FOR    //
//    //DEGENS    //
//                //
//                //
////////////////////


contract FFD is ERC721Creator {
    constructor() ERC721Creator("FOOD FOR DEGENS", "FFD") {}
}