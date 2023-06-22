// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: theSundaysCoverArt
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////
//                                                                  //
//                                                                  //
//    We are all living in different stories with one another...    //
//                                                                  //
//                                                                  //
//////////////////////////////////////////////////////////////////////


contract SCArt is ERC1155Creator {
    constructor() ERC1155Creator("theSundaysCoverArt", "SCArt") {}
}