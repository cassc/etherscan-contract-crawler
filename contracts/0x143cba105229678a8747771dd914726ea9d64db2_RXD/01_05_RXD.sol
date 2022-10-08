// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: RANXDEER EDs.
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////
//                //
//                //
//    RANXDEER    //
//                //
//                //
////////////////////


contract RXD is ERC721Creator {
    constructor() ERC721Creator("RANXDEER EDs.", "RXD") {}
}