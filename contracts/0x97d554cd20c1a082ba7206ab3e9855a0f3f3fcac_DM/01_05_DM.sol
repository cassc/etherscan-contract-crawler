// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: David's Mint
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////
//          //
//          //
//    DM    //
//          //
//          //
//////////////


contract DM is ERC1155Creator {
    constructor() ERC1155Creator("David's Mint", "DM") {}
}