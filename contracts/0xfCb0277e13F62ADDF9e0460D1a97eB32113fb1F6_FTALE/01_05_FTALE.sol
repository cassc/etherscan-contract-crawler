// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fairy Tales
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                         //
//                                                                                         //
//    This is a collection of unusual and kind stories in illustrations. Fairy stories.    //
//                                                                                         //
//                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////


contract FTALE is ERC1155Creator {
    constructor() ERC1155Creator("Fairy Tales", "FTALE") {}
}