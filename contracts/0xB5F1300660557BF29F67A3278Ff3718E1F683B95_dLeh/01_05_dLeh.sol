// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: une histoire de mélancolie
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////
//                           //
//                           //
//    dieLehmanns // uHdM    //
//                           //
//                           //
///////////////////////////////


contract dLeh is ERC721Creator {
    constructor() ERC721Creator(unicode"une histoire de mélancolie", "dLeh") {}
}