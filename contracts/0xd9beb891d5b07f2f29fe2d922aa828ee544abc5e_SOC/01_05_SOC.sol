// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Scenes of The Crime
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////
//                     //
//                     //
//    conte_digital    //
//                     //
//                     //
/////////////////////////


contract SOC is ERC721Creator {
    constructor() ERC721Creator("Scenes of The Crime", "SOC") {}
}