// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: L0V3.1
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////
//                  //
//                  //
//    ｡ﾟﾟ･｡･ﾟﾟ｡     //
//    ﾟ。 L0V3.1     //
//    　ﾟ･｡･ﾟ        //
//                  //
//                  //
//////////////////////


contract L0V3 is ERC1155Creator {
    constructor() ERC1155Creator("L0V3.1", "L0V3") {}
}