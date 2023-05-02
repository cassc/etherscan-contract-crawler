// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: STAND WITH PEPE
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////
//                             //
//                             //
//    STAND ON PEPE WITH US    //
//                             //
//                             //
/////////////////////////////////


contract PEPE is ERC1155Creator {
    constructor() ERC1155Creator("STAND WITH PEPE", "PEPE") {}
}