// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Storytime DAO Membership
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////
//                          //
//                          //
//    The History of Now    //
//                          //
//                          //
//////////////////////////////


contract sdm is ERC721Creator {
    constructor() ERC721Creator("Storytime DAO Membership", "sdm") {}
}