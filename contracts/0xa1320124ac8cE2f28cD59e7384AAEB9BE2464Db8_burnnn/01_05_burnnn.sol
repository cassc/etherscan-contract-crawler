// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Burn and redeem test contract
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////
//          //
//          //
//    dd    //
//          //
//          //
//////////////


contract burnnn is ERC1155Creator {
    constructor() ERC1155Creator("Burn and redeem test contract", "burnnn") {}
}