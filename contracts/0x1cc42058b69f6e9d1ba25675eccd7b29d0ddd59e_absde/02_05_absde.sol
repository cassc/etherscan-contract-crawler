// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Abstract Dementia
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//    Abstract Dementia    //
//    By Wilman Aro        //
//                         //
//                         //
/////////////////////////////


contract absde is ERC721Creator {
    constructor() ERC721Creator("Abstract Dementia", "absde") {}
}