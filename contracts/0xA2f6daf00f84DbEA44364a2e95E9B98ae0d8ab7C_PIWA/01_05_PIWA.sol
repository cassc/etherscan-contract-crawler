// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pepe in West America
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////
//                            //
//                            //
//    PEPE IN WEST AMERICA    //
//                            //
//                            //
////////////////////////////////


contract PIWA is ERC721Creator {
    constructor() ERC721Creator("Pepe in West America", "PIWA") {}
}