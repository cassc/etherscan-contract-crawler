// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Adeylart
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////
//          //
//          //
//    kk    //
//          //
//          //
//////////////


contract ADELE is ERC1155Creator {
    constructor() ERC1155Creator("Adeylart", "ADELE") {}
}