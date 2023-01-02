// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Cards
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//                    //
//    ╔═╗╔═╗╦═╗╔╦╗    //
//    ║  ╠═╣╠╦╝ ║║    //
//    ╚═╝╩ ╩╩╚══╩╝    //
//                    //
//                    //
//                    //
////////////////////////


contract CARD is ERC721Creator {
    constructor() ERC721Creator("Cards", "CARD") {}
}