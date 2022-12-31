// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 生きた土
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////
//                    //
//                    //
//    IKITA TSUCHI    //
//                    //
//                    //
////////////////////////


contract IT is ERC721Creator {
    constructor() ERC721Creator(unicode"生きた土", "IT") {}
}