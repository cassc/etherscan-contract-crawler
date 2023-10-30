// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: JERKS LORE
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//     ╦╔═╗╦═╗╦╔═╔═╗  ╦  ╔═╗╦═╗╔═╗    //
//     ║║╣ ╠╦╝╠╩╗╚═╗  ║  ║ ║╠╦╝║╣     //
//    ╚╝╚═╝╩╚═╩ ╩╚═╝  ╩═╝╚═╝╩╚═╚═╝    //
//                                    //
//                                    //
////////////////////////////////////////


contract JERKSLORE is ERC721Creator {
    constructor() ERC721Creator("JERKS LORE", "JERKSLORE") {}
}