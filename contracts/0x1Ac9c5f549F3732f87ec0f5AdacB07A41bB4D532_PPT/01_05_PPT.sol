// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Paji's Project Ticket
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////
//            //
//            //
//    paji    //
//            //
//            //
////////////////


contract PPT is ERC1155Creator {
    constructor() ERC1155Creator("Paji's Project Ticket", "PPT") {}
}