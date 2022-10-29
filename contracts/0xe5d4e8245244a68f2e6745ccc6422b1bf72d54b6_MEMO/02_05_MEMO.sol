// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Memory Collage
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////
//                             //
//                             //
//            .---.            //
//            |[X]|            //
//     _.==._.""""".___n__     //
//    d __ ___.-''-. _____b    //
//    |[__]  /."""".\ _   |    //
//    |     // /""\ \\_)  |    //
//    |     \\ \__/ //    |    //
//    |BACCA \`.__.'/PHOTO|    //
//    \=======`-..-'======/    //
//     `-----------------'     //
//                             //
//                             //
/////////////////////////////////


contract MEMO is ERC721Creator {
    constructor() ERC721Creator("Memory Collage", "MEMO") {}
}