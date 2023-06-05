// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mask
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////
//                        //
//                        //
//    @imakesupersuits    //
//                        //
//                        //
////////////////////////////


contract MSK is ERC721Creator {
    constructor() ERC721Creator("Mask", "MSK") {}
}