// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pepe's Milk
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////
//                   //
//                   //
//    PEPE'S MILK    //
//                   //
//                   //
///////////////////////


contract PPM is ERC1155Creator {
    constructor() ERC1155Creator("Pepe's Milk", "PPM") {}
}