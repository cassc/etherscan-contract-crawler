// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Checks - Lover Boy Edition
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//    Checks - Lover Boy Edition    //
//                                  //
//                                  //
//////////////////////////////////////


contract LB is ERC721Creator {
    constructor() ERC721Creator("Checks - Lover Boy Edition", "LB") {}
}