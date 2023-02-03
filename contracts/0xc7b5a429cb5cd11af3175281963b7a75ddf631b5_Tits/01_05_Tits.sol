// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Tits
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////
//              //
//              //
//    Hoffer    //
//              //
//              //
//////////////////


contract Tits is ERC1155Creator {
    constructor() ERC1155Creator("Tits", "Tits") {}
}