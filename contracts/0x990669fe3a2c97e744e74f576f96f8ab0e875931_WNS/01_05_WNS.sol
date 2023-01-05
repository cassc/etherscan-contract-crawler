// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Web 3 Never Sleeps
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////
//                            //
//                            //
//    Degens Never Sleep.     //
//                            //
//                            //
////////////////////////////////


contract WNS is ERC721Creator {
    constructor() ERC721Creator("Web 3 Never Sleeps", "WNS") {}
}