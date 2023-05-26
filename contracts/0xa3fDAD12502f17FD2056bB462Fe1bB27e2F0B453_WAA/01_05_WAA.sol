// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Wiley's Abstract Art
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////
//                            //
//                            //
//    Wiley's Abstract Art    //
//                            //
//                            //
////////////////////////////////


contract WAA is ERC721Creator {
    constructor() ERC721Creator("Wiley's Abstract Art", "WAA") {}
}