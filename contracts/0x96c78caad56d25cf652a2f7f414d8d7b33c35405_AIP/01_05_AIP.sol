// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AI photography - Hana Auerová
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////
//                                      //
//                                      //
//    AI photography by Hana Auerová    //
//                                      //
//                                      //
//////////////////////////////////////////


contract AIP is ERC721Creator {
    constructor() ERC721Creator(unicode"AI photography - Hana Auerová", "AIP") {}
}