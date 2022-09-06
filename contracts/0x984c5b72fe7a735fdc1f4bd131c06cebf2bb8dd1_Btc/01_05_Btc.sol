// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bitcoin NFT
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////
//                   //
//                   //
//    BITCOIN NFT    //
//                   //
//                   //
///////////////////////


contract Btc is ERC721Creator {
    constructor() ERC721Creator("Bitcoin NFT", "Btc") {}
}