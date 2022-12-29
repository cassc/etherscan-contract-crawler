// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Baudrillard, Barthes & Balenciaga
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//                       //
//     __   __   __      //
//    |__) |__) |__)     //
//    |__) |__) |__)     //
//                       //
//                       //
//                       //
//                       //
//                       //
///////////////////////////


contract BBB is ERC721Creator {
    constructor() ERC721Creator("Baudrillard, Barthes & Balenciaga", "BBB") {}
}