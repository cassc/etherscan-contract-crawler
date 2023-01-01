// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Alexes Premiere
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//    Alexes Premiere    //
//                       //
//                       //
///////////////////////////


contract AP2022 is ERC721Creator {
    constructor() ERC721Creator("Alexes Premiere", "AP2022") {}
}