// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: #CURATIO
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////
//                            //
//                            //
//    HYPEPULSE COLLECTION    //
//                            //
//                            //
////////////////////////////////


contract ARTK is ERC721Creator {
    constructor() ERC721Creator("#CURATIO", "ARTK") {}
}