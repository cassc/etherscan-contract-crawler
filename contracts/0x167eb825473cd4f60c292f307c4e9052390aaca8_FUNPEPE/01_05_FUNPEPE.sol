// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FUNPEPE
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////
//                     //
//                     //
//    FUN & CULTURE    //
//                     //
//                     //
/////////////////////////


contract FUNPEPE is ERC1155Creator {
    constructor() ERC1155Creator("FUNPEPE", "FUNPEPE") {}
}