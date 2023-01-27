// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: the collection by mrdifficult
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////
//                   //
//                   //
//    MrDifficult    //
//                   //
//                   //
///////////////////////


contract mrd is ERC1155Creator {
    constructor() ERC1155Creator("the collection by mrdifficult", "mrd") {}
}