// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NFSC x Worm Special
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////
//                //
//                //
//    nfsc-wrm    //
//                //
//                //
////////////////////


contract NFSCWRM is ERC721Creator {
    constructor() ERC721Creator("NFSC x Worm Special", "NFSCWRM") {}
}