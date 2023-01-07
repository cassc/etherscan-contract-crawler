// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Unstable Faith
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////
//          //
//          //
//    UF    //
//          //
//          //
//////////////


contract SUFI is ERC1155Creator {
    constructor() ERC1155Creator("Unstable Faith", "SUFI") {}
}