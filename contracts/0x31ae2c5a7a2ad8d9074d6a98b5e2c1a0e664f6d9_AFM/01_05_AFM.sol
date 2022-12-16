// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: A few moons
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////
//                         //
//                         //
//                         //
//        _,.---._         //
//      ,-.' , -  `.       //
//     /==/_,  ,  - \      //
//    |==|   .=.     |     //
//    |==|_ : ;=:  - |     //
//    |==| , '='     |     //
//     \==\ -    ,_ /      //
//      '.='. -   .'       //
//        `--`--''         //
//                         //
//                         //
//                         //
/////////////////////////////


contract AFM is ERC721Creator {
    constructor() ERC721Creator("A few moons", "AFM") {}
}