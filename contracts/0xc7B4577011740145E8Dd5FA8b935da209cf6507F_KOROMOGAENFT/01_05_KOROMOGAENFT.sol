// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: KOROMOGAE NFT
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////
//            //
//            //
//    2023    //
//            //
//            //
////////////////


contract KOROMOGAENFT is ERC1155Creator {
    constructor() ERC1155Creator("KOROMOGAE NFT", "KOROMOGAENFT") {}
}