// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NonFungibleLov3
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////
//                        //
//                        //
//    NonFungibleLaura    //
//                        //
//                        //
////////////////////////////


contract NFlove is ERC1155Creator {
    constructor() ERC1155Creator("NonFungibleLov3", "NFlove") {}
}