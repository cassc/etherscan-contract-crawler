// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Crossroads by Mikk
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////
//                          //
//                          //
//    Crossroads by Mikk    //
//                          //
//                          //
//////////////////////////////


contract MIKK is ERC1155Creator {
    constructor() ERC1155Creator("Crossroads by Mikk", "MIKK") {}
}