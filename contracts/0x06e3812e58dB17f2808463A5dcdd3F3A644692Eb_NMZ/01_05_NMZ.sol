// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NAMAZUDAO
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//    NAMAZUDAOxxxNAMAZUDAOxxxNAMAZUDAO    //
//    xxxxxxNAMAZUDAOxxxNAMAZUDAOxxxxxx    //
//    NAMAZUDAOxxxNAMAZUDAOxxxNAMAZUDAO    //
//                                         //
//                                         //
/////////////////////////////////////////////


contract NMZ is ERC1155Creator {
    constructor() ERC1155Creator("NAMAZUDAO", "NMZ") {}
}