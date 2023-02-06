// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TRAINY MCTRAIN FACE
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////
//                              //
//                              //
//    Just the tip into NFTs    //
//                              //
//                              //
//////////////////////////////////


contract TMF is ERC1155Creator {
    constructor() ERC1155Creator("TRAINY MCTRAIN FACE", "TMF") {}
}