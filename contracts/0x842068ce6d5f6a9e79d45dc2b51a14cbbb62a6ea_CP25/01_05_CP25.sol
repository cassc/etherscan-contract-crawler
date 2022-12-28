// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Drunk Santa's presents  - cryptopainter
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////
//          //
//          //
//    CP    //
//          //
//          //
//////////////


contract CP25 is ERC1155Creator {
    constructor() ERC1155Creator("Drunk Santa's presents  - cryptopainter", "CP25") {}
}