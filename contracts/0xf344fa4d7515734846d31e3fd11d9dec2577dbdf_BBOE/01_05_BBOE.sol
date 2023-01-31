// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: OE of Bobby
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////
//          //
//          //
//    :)    //
//          //
//          //
//////////////


contract BBOE is ERC1155Creator {
    constructor() ERC1155Creator("OE of Bobby", "BBOE") {}
}