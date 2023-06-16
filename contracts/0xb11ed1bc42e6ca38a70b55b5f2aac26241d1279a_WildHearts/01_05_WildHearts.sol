// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Wild Hearts
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//    .  . .  .  .  .          ,          //
//    |  |*| _|  |__| _  _.._.-+- __      //
//    |/\|||(_]  |  |(/,(_][   | _)       //
//                                        //
//    by Kipheo Art / Starfire Designs    //
//                                        //
//                                        //
////////////////////////////////////////////


contract WildHearts is ERC721Creator {
    constructor() ERC721Creator("Wild Hearts", "WildHearts") {}
}