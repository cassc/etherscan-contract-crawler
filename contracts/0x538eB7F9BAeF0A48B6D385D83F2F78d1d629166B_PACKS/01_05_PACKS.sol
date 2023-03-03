// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Packs by Index Card
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////
//                        //
//                        //
//    ░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░░░░    //
//    ░░░░░░░░░░░░░░░░    //
//        ░░░░░░░░        //
//        ░ ░░░░░░        //
//        ░ ░░░░░░        //
//                        //
//                        //
////////////////////////////


contract PACKS is ERC1155Creator {
    constructor() ERC1155Creator("Packs by Index Card", "PACKS") {}
}