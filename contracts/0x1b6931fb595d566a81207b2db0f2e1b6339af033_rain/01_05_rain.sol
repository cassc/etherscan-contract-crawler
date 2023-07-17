// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: amayadori_NFT Thanks Collection
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////
//                //
//                //
//     /_/        //
//    ( o.o )     //
//     > ^ <      //
//                //
//                //
//                //
////////////////////


contract rain is ERC1155Creator {
    constructor() ERC1155Creator("amayadori_NFT Thanks Collection", "rain") {}
}