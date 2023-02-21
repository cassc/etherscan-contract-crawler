// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MUSE
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////
//                                                                              //
//                                                                              //
//    MUSE is a blockchain based entertainment collective founded by jlove.     //
//                                                                              //
//    Thank you for your time and attention.                                    //
//                                                                              //
//                                                                              //
//////////////////////////////////////////////////////////////////////////////////


contract MUSE is ERC721Creator {
    constructor() ERC721Creator("MUSE", "MUSE") {}
}