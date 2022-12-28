// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Venere Gallery Curated
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//    VENERE GALLERY CURATED DROPS    //
//                                    //
//                                    //
////////////////////////////////////////


contract VNR is ERC721Creator {
    constructor() ERC721Creator("Venere Gallery Curated", "VNR") {}
}