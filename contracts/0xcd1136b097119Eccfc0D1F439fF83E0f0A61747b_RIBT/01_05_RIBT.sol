// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Run it back Turbo
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////
//                         //
//                         //
//    Run it back Turbo    //
//                         //
//                         //
/////////////////////////////


contract RIBT is ERC1155Creator {
    constructor() ERC1155Creator("Run it back Turbo", "RIBT") {}
}