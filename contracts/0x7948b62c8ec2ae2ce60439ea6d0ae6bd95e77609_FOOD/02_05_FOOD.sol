// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Power Lunch NFT
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//             __                 _             //
//            / _| ___   ___   __| |            //
//           | |_ / _ \ / _ \ / _` |            //
//           |  _| (_) | (_) | (_| |            //
//           |_|  \___/ \___/ \__,_|            //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract FOOD is ERC721Creator {
    constructor() ERC721Creator("Power Lunch NFT", "FOOD") {}
}