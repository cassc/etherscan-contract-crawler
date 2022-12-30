// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: schauermann x2
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////
//            //
//            //
//    ☁️☁️    //
//            //
//            //
////////////////


contract schauermannx2 is ERC1155Creator {
    constructor() ERC1155Creator("schauermann x2", "schauermannx2") {}
}