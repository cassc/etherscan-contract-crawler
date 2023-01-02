// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DressnDraw
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////
//                             //
//                             //
//       ___          ___      //
//       /   \_ __    /   \    //
//      / /\ / '_ \  / /\ /    //
//     / /_//| | | |/ /_//     //
//    /___,' |_| |_/___,'      //
//                             //
//                             //
/////////////////////////////////


contract DnD is ERC721Creator {
    constructor() ERC721Creator("DressnDraw", "DnD") {}
}