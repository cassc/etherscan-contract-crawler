// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PFP WARDROBE
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    PFP WARDROBE    //
//                    //
//                    //
////////////////////////


contract PW is ERC721Creator {
    constructor() ERC721Creator("PFP WARDROBE", "PW") {}
}