// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Without a Map
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////
//                              //
//                              //
//            .---.             //
//            |[X]|             //
//     _.==._.""""".___n__      //
//    d __ ___.-''-. _____b     //
//    |[__]  /."""".\ _   |     //
//    |     // /""\ \\_)  |     //
//    |     \\ \__/ //    |     //
//    |pentax\`.__.'/     |     //
//    \=======`-..-'======/     //
//     `-----------------'      //
//                              //
//                              //
//////////////////////////////////


contract WAM is ERC721Creator {
    constructor() ERC721Creator("Without a Map", "WAM") {}
}