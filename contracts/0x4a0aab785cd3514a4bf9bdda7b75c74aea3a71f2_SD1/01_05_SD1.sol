// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Stephan Dybus
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////
//                        //
//                        //
//       ___      _       //
//      (___)    / )      //
//       ___    / /       //
//      (___)  (_/        //
//                        //
//                        //
////////////////////////////


contract SD1 is ERC721Creator {
    constructor() ERC721Creator("Stephan Dybus", "SD1") {}
}