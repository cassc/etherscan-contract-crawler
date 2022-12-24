// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fujika Open Edition
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////
//                   //
//                   //
//    ( ◜௰◝و(و "♪    //
//                   //
//                   //
///////////////////////


contract FOE is ERC1155Creator {
    constructor() ERC1155Creator("Fujika Open Edition", "FOE") {}
}