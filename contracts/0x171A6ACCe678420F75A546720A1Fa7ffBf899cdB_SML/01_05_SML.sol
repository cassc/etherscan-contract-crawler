// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Superman the legend
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////
//                            //
//                            //
//    Superman the legend     //
//                            //
//                            //
////////////////////////////////


contract SML is ERC721Creator {
    constructor() ERC721Creator("Superman the legend", "SML") {}
}