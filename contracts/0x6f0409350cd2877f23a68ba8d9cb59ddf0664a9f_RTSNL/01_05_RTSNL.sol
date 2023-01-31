// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Absolutely Artisanal
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////
//                            //
//                            //
//    Absolutely Artisanal    //
//                            //
//                            //
////////////////////////////////


contract RTSNL is ERC1155Creator {
    constructor() ERC1155Creator("Absolutely Artisanal", "RTSNL") {}
}