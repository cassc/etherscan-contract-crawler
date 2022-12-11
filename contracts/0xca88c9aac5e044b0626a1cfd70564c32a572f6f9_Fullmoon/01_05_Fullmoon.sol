// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: full moon collection 2022
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////
//               //
//               //
//    (*'-'*)    //
//               //
//               //
///////////////////


contract Fullmoon is ERC1155Creator {
    constructor() ERC1155Creator("full moon collection 2022", "Fullmoon") {}
}