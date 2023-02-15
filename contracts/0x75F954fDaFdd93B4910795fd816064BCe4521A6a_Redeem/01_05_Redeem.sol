// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Trial Redeem
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////
//              //
//              //
//    Redeem    //
//              //
//              //
//////////////////


contract Redeem is ERC1155Creator {
    constructor() ERC1155Creator("Trial Redeem", "Redeem") {}
}