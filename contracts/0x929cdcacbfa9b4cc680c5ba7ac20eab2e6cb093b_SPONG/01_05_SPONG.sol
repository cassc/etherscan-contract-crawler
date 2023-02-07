// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Checks - SpongeBob Edition
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//    This SpongeBob may or may not be notable.    //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract SPONG is ERC1155Creator {
    constructor() ERC1155Creator("Checks - SpongeBob Edition", "SPONG") {}
}