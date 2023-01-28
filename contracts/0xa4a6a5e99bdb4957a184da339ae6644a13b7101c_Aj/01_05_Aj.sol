// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Arts and culture
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                //
//                                                                                                //
//    A full time charcoal pencil artist that speaks for those who can’t speak for themselves     //
//                                                                                                //
//                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////


contract Aj is ERC721Creator {
    constructor() ERC721Creator("Arts and culture", "Aj") {}
}