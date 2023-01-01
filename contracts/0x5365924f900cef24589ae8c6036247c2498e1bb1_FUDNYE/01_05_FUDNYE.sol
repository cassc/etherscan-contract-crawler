// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fudder NYE Party
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////
//           //
//           //
//    Fud    //
//           //
//           //
///////////////


contract FUDNYE is ERC1155Creator {
    constructor() ERC1155Creator("Fudder NYE Party", "FUDNYE") {}
}