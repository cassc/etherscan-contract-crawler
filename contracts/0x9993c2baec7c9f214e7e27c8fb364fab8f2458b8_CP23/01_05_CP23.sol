// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: cryptopainter burn for PFP features
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////
//          //
//          //
//    CP    //
//          //
//          //
//////////////


contract CP23 is ERC1155Creator {
    constructor() ERC1155Creator("cryptopainter burn for PFP features", "CP23") {}
}