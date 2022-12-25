// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LoveUni Souvenir
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////
//                     //
//                     //
//    AI_Love_Union    //
//                     //
//                     //
/////////////////////////


contract ALU is ERC1155Creator {
    constructor() ERC1155Creator("LoveUni Souvenir", "ALU") {}
}