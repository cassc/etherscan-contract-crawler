// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: TT editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////
//          //
//          //
//    TT    //
//          //
//          //
//////////////


contract TTeditions is ERC1155Creator {
    constructor() ERC1155Creator("TT editions", "TTeditions") {}
}