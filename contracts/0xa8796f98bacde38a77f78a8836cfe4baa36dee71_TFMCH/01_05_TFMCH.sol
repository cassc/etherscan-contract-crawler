// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Free Mint Chocolate
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////
//            //
//            //
//    §8-)    //
//            //
//            //
////////////////


contract TFMCH is ERC1155Creator {
    constructor() ERC1155Creator("The Free Mint Chocolate", "TFMCH") {}
}