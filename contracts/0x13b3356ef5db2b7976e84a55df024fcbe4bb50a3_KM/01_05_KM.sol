// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Works by Kelly Milligan
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////
//                                                              //
//                                                              //
//                                                              //
//     |   _  | |    ._ _  o | | o  _   _. ._     _. ._ _|_     //
//     |< (/_ | | \/ | | | | | | | (_| (_| | | o (_| |   |_     //
//                /                 _|                          //
//                                                              //
//                                                              //
//////////////////////////////////////////////////////////////////


contract KM is ERC721Creator {
    constructor() ERC721Creator("Works by Kelly Milligan", "KM") {}
}