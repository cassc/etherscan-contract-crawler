// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Winter Open Edition
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////
//                         //
//                         //
//    it’s pure cold eh    //
//                         //
//                         //
/////////////////////////////


contract SNOW is ERC1155Creator {
    constructor() ERC1155Creator("Winter Open Edition", "SNOW") {}
}