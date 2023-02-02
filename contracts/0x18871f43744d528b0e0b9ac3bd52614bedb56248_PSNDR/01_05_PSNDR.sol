// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: pepessandro editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////
//            //
//            //
//    0000    //
//            //
//            //
////////////////


contract PSNDR is ERC1155Creator {
    constructor() ERC1155Creator("pepessandro editions", "PSNDR") {}
}