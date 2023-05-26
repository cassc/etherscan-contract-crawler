// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Erosprites
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////
//            //
//            //
//    shit    //
//            //
//            //
////////////////


contract EROS is ERC1155Creator {
    constructor() ERC1155Creator("Erosprites", "EROS") {}
}