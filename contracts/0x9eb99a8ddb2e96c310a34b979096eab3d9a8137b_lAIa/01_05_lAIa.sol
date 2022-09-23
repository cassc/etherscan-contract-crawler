// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: literallAI artworks
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//                                    //
//    ┬  ┬┌┬┐┌─┐┬─┐┌─┐┬  ┬  ╔═╗╦      //
//    │  │ │ ├┤ ├┬┘├─┤│  │  ╠═╣║      //
//    ┴─┘┴ ┴ └─┘┴└─┴ ┴┴─┘┴─┘╩ ╩╩      //
//    ____________________________    //
//                                    //
//                                    //
////////////////////////////////////////


contract lAIa is ERC721Creator {
    constructor() ERC721Creator("literallAI artworks", "lAIa") {}
}