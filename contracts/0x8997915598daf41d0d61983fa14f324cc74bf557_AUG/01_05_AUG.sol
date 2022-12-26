// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DarkMarkArt
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////
//                                  //
//                                  //
//    Photographer lost ion Lust    //
//                                  //
//                                  //
//////////////////////////////////////


contract AUG is ERC1155Creator {
    constructor() ERC1155Creator("DarkMarkArt", "AUG") {}
}