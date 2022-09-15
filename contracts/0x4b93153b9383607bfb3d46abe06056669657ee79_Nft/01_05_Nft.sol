// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: test
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////
//          //
//          //
//    Hi    //
//          //
//          //
//////////////


contract Nft is ERC721Creator {
    constructor() ERC721Creator("test", "Nft") {}
}