// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Glitchy Kisses
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////
//                                                    //
//                                                    //
//    how sweet it is that our glitches are kisses    //
//                                                    //
//                                                    //
////////////////////////////////////////////////////////


contract KISS is ERC1155Creator {
    constructor() ERC1155Creator("Glitchy Kisses", "KISS") {}
}