// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mail A Day
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////
//          //
//          //
//    <3    //
//          //
//          //
//////////////


contract MAD is ERC1155Creator {
    constructor() ERC1155Creator("Mail A Day", "MAD") {}
}