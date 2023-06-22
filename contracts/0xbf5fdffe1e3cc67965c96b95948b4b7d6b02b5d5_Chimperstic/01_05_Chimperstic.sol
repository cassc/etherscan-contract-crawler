// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Chimperstic Chimpers
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////
//                            //
//                            //
//    Chimperstic Chimpers    //
//                            //
//                            //
////////////////////////////////


contract Chimperstic is ERC1155Creator {
    constructor() ERC1155Creator("Chimperstic Chimpers", "Chimperstic") {}
}