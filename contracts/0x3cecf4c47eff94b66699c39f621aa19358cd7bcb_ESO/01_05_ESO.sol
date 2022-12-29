// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Esoteros Renaissance
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////
//                            //
//                            //
//    The answer is in art    //
//                            //
//                            //
////////////////////////////////


contract ESO is ERC721Creator {
    constructor() ERC721Creator("Esoteros Renaissance", "ESO") {}
}