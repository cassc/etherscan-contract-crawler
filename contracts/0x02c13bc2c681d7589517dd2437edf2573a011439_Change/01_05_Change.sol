// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Metamorphosis Bidders edition (Self isolation)
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////
//          //
//          //
//    <3    //
//          //
//          //
//////////////


contract Change is ERC1155Creator {
    constructor() ERC1155Creator("Metamorphosis Bidders edition (Self isolation)", "Change") {}
}