// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Holidays
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//                                                 //
//      _    _       _ _     _                     //
//     | |  | |     | (_)   | |                    //
//     | |__| | ___ | |_  __| | __ _ _   _ ___     //
//     |  __  |/ _ \| | |/ _` |/ _` | | | / __|    //
//     | |  | | (_) | | | (_| | (_| | |_| \__ \    //
//     |_|  |_|\___/|_|_|\__,_|\__,_|\__, |___/    //
//                                    __/ |        //
//                                   |___/         //
//                                                 //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////


contract HLDS is ERC721Creator {
    constructor() ERC721Creator("Holidays", "HLDS") {}
}