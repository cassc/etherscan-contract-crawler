// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Here Come Dat $PEPE
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////
//            //
//            //
//    PEPE    //
//            //
//            //
////////////////


contract PEPE is ERC1155Creator {
    constructor() ERC1155Creator("Here Come Dat $PEPE", "PEPE") {}
}