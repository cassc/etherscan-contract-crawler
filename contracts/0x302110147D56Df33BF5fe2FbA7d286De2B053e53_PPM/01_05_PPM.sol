// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pepemate
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////
//               //
//               //
//    Apophis    //
//               //
//               //
///////////////////


contract PPM is ERC1155Creator {
    constructor() ERC1155Creator("Pepemate", "PPM") {}
}