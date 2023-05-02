// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Manifold Editions
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    conte_digital    //
//                     //
//                     //
/////////////////////////


contract MED is ERC721Creator {
    constructor() ERC721Creator("Manifold Editions", "MED") {}
}