// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BoredApe
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////
//                            //
//                            //
//    Bored Ape Yacht Club    //
//                            //
//                            //
////////////////////////////////


contract BAYC is ERC721Creator {
    constructor() ERC721Creator("BoredApe", "BAYC") {}
}