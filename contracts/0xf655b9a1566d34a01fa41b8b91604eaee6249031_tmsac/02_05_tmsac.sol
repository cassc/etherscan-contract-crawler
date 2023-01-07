// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Tomoya's Art Collection
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////
//                    //
//                    //
//    tomoya's art    //
//                    //
//                    //
////////////////////////


contract tmsac is ERC1155Creator {
    constructor() ERC1155Creator("Tomoya's Art Collection", "tmsac") {}
}