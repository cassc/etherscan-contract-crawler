// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pepe - Checks Edition
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////
//                                                        //
//                                                        //
//    Filippos Pente | Logo Creator and Visual Artist     //
//    https://linktr.ee/mistershot                        //
//                                                        //
//                                                        //
////////////////////////////////////////////////////////////


contract PEPECHECKS is ERC721Creator {
    constructor() ERC721Creator("Pepe - Checks Edition", "PEPECHECKS") {}
}