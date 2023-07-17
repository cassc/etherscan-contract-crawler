// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Luxury cars
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////
//                            //
//                            //
//    11000100101100111001    //
//                            //
//                            //
////////////////////////////////


contract LCR is ERC721Creator {
    constructor() ERC721Creator("Luxury cars", "LCR") {}
}