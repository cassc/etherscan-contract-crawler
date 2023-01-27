// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FAKEREKT
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////
//                       //
//                       //
//                       //
//    __________.___     //
//    \______   \   |    //
//     |     ___/   |    //
//     |    |   |   |    //
//     |____|   |___|    //
//                       //
//                       //
//                       //
///////////////////////////


contract FRKT is ERC1155Creator {
    constructor() ERC1155Creator("FAKEREKT", "FRKT") {}
}