// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Yasuyon Mama Note
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////
//           //
//           //
//    YMN    //
//           //
//           //
///////////////


contract YMN is ERC1155Creator {
    constructor() ERC1155Creator("Yasuyon Mama Note", "YMN") {}
}