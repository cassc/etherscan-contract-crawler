// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Butaverse Pass Benefit Collection
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////
//                             //
//                             //
//    豚バースPASSの特典コレクションです🐷    //
//                             //
//                             //
/////////////////////////////////


contract BUTAVERSEPASSBENEFITCOLLECTION is ERC1155Creator {
    constructor() ERC1155Creator("Butaverse Pass Benefit Collection", "BUTAVERSEPASSBENEFITCOLLECTION") {}
}