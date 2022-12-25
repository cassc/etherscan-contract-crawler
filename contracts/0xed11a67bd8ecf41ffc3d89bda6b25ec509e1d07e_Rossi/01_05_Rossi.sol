// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Season
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////
//              //
//              //
//    season    //
//              //
//              //
//////////////////


contract Rossi is ERC1155Creator {
    constructor() ERC1155Creator("Season", "Rossi") {}
}