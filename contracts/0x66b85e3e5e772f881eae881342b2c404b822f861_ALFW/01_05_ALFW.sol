// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: A Loss for Words
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//                _                    _     _     //
//               | |                  | |   | |    //
//      __ _ _ __| |___      __   _ __| | __| |    //
//     / _` | ‘__| __\ \ /\ / /  | ‘__| |/ _` |    //
//    | (_| | |  | |_ \ V  V /   | |  | | (_| |    //
//     \__,_|_|   \__| \_/\_/    |_|  |_|\__,_|    //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract ALFW is ERC721Creator {
    constructor() ERC721Creator("A Loss for Words", "ALFW") {}
}