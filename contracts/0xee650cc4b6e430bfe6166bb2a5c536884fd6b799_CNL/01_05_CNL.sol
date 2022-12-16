// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CyrptoNinjaLove
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////
//                       //
//                       //
//    CryptoNinjaLove    //
//                       //
//                       //
///////////////////////////


contract CNL is ERC721Creator {
    constructor() ERC721Creator("CyrptoNinjaLove", "CNL") {}
}