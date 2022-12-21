// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ITINERANT
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////
//             //
//             //
//    ITRNT    //
//             //
//             //
/////////////////


contract ITRNT is ERC721Creator {
    constructor() ERC721Creator("ITINERANT", "ITRNT") {}
}