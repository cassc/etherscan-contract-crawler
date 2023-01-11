// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Hup
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////
//                    //
//                    //
//    Hup Editions    //
//                    //
//                    //
////////////////////////


contract HUP is ERC1155Creator {
    constructor() ERC1155Creator("Hup", "HUP") {}
}