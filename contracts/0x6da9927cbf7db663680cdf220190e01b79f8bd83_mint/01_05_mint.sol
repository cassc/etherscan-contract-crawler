// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mintbase
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    --_-_-_-_---    //
//       -_-_-_       //
//        -_-_-       //
//         -__-       //
//        _-_         //
//       _-           //
//       -_           //
//        _-_         //
//                    //
//                    //
////////////////////////


contract mint is ERC721Creator {
    constructor() ERC721Creator("Mintbase", "mint") {}
}