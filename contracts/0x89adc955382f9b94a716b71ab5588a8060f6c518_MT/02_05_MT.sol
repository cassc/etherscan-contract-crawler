// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: doggy
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                                                                            //
//    If Gale Song's second-zone bitmap is fully differential and multiple    //
//                                                                            //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////


contract MT is ERC721Creator {
    constructor() ERC721Creator("doggy", "MT") {}
}