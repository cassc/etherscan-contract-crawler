// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Cyber Special Editions
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//    Special Edition Collection    //
//                                  //
//                                  //
//////////////////////////////////////


contract CybrSE is ERC721Creator {
    constructor() ERC721Creator("Cyber Special Editions", "CybrSE") {}
}