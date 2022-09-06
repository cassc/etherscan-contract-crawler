// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: cryptopainter
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////
//          //
//          //
//    cp    //
//          //
//          //
//////////////


contract CP is ERC721Creator {
    constructor() ERC721Creator("cryptopainter", "CP") {}
}