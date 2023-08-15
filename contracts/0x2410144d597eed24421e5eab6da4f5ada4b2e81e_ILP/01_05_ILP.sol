// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: I Love Pixels
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////
//                     //
//                     //
//    I Love Pixels    //
//                     //
//                     //
/////////////////////////


contract ILP is ERC1155Creator {
    constructor() ERC1155Creator("I Love Pixels", "ILP") {}
}