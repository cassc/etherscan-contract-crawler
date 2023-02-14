// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: OdoshiProject
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////
//                      //
//                      //
//    Odoshi Project    //
//                      //
//                      //
//////////////////////////


contract OPJ is ERC1155Creator {
    constructor() ERC1155Creator("OdoshiProject", "OPJ") {}
}