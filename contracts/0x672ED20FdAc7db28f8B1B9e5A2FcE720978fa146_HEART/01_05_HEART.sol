// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Hearty Homies
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////
//          //
//          //
//    <3    //
//          //
//          //
//////////////


contract HEART is ERC1155Creator {
    constructor() ERC1155Creator("Hearty Homies", "HEART") {}
}