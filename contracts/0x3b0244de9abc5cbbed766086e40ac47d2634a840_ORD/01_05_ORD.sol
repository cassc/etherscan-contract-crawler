// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ordinals on ETH (OE)
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////
//                            //
//                            //
//    Ordinals on ETH (OE)    //
//                            //
//                            //
////////////////////////////////


contract ORD is ERC721Creator {
    constructor() ERC721Creator("Ordinals on ETH (OE)", "ORD") {}
}