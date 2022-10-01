// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GIFT
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//      ________._________________________    //
//     /  _____/|   \_   _____/\__    ___/    //
//    /   \  ___|   ||    __)    |    |       //
//    \    \_\  \   ||     \     |    |       //
//     \______  /___|\___  /     |____|       //
//            \/         \/                   //
//                                            //
//                                            //
////////////////////////////////////////////////


contract GIFT is ERC721Creator {
    constructor() ERC721Creator("GIFT", "GIFT") {}
}