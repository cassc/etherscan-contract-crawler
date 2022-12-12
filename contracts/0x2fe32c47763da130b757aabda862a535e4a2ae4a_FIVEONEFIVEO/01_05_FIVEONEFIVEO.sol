// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 5150_001
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//    _____    ________ _______       //
//    \__  \  / ____/  |  \__  \      //
//     / __ \< <_|  |  |  // __ \_    //
//    (____  /\__   |____/(____  /    //
//         \/    |__|          \/     //
//                                    //
//                                    //
////////////////////////////////////////


contract FIVEONEFIVEO is ERC721Creator {
    constructor() ERC721Creator("5150_001", "FIVEONEFIVEO") {}
}