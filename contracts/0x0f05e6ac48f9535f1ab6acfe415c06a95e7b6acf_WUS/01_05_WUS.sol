// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: WEALTHY USA STATES
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//    FOR THE BLUE BLOODS ONLY     //
//                                 //
//                                 //
/////////////////////////////////////


contract WUS is ERC721Creator {
    constructor() ERC721Creator("WEALTHY USA STATES", "WUS") {}
}