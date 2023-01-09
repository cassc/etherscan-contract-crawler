// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TRIPPY TROMP
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////
//                        //
//                        //
//    Trippy Tromp NFT    //
//                        //
//                        //
////////////////////////////


contract TROMP is ERC1155Creator {
    constructor() ERC1155Creator("TRIPPY TROMP", "TROMP") {}
}