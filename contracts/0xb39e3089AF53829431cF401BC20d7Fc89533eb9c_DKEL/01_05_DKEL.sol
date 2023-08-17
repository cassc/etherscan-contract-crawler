// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Dankbar Elements
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////
//                                   //
//                                   //
//    Dankbar Elements by NFTLord    //
//                                   //
//                                   //
///////////////////////////////////////


contract DKEL is ERC1155Creator {
    constructor() ERC1155Creator("Dankbar Elements", "DKEL") {}
}