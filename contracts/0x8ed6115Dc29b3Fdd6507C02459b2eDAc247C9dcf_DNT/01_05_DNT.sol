// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Donate
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                     //
//                                                                                     //
//    All proceeds from the sales of this work will be donated to Dude for Turkey,     //
//    which suffered a major earthquake disaster in February 2023.                     //
//                                                                                     //
//                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////


contract DNT is ERC721Creator {
    constructor() ERC721Creator("Donate", "DNT") {}
}