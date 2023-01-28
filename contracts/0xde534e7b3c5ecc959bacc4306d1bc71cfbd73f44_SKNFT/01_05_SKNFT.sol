// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Skeleton Balloon
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////
//                            //
//                            //
//    Skeleton Balloon NFT    //
//                            //
//                            //
////////////////////////////////


contract SKNFT is ERC1155Creator {
    constructor() ERC1155Creator("Skeleton Balloon", "SKNFT") {}
}