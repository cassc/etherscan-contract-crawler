// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Test by MW
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////
//          //
//          //
//    yo    //
//          //
//          //
//////////////


contract TBMW is ERC1155Creator {
    constructor() ERC1155Creator("Test by MW", "TBMW") {}
}