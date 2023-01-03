// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: yoosle
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////
//              //
//              //
//    yoosle    //
//              //
//              //
//////////////////


contract ysle is ERC1155Creator {
    constructor() ERC1155Creator("yoosle", "ysle") {}
}