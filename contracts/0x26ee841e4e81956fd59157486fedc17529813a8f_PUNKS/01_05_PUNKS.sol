// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CryptoPunKs
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    CryptoPunKs    //
//                   //
//                   //
///////////////////////


contract PUNKS is ERC721Creator {
    constructor() ERC721Creator(unicode"CryptoPunKs", "PUNKS") {}
}