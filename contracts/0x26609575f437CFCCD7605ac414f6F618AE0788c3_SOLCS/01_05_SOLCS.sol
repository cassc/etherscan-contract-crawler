// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Communal Sacrifices (Skulls of Lucifer)
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//                                                                          //
//    Talismans of appreciation for the owners of The Skulls of Lucifer.    //
//                                                                          //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////


contract SOLCS is ERC1155Creator {
    constructor() ERC1155Creator("Communal Sacrifices (Skulls of Lucifer)", "SOLCS") {}
}