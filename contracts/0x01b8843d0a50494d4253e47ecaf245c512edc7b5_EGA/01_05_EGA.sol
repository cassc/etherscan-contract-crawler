// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Exploration of Glitch Art by Chain Virus
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//    Exploration of Glitch Art by Chain Virus    //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract EGA is ERC1155Creator {
    constructor() ERC1155Creator("Exploration of Glitch Art by Chain Virus", "EGA") {}
}