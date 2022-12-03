// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DeadGuys-Mag
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////
//                   //
//                   //
//    GiF or Die!    //
//                   //
//                   //
///////////////////////


contract DGM is ERC1155Creator {
    constructor() ERC1155Creator("DeadGuys-Mag", "DGM") {}
}