// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mergepepe
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////
//                        //
//                        //
//    Non Fungible Nat    //
//                        //
//                        //
////////////////////////////


contract MRGPPE is ERC721Creator {
    constructor() ERC721Creator("Mergepepe", "MRGPPE") {}
}