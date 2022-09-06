// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Manos
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////
//                                                   //
//                                                   //
//    .__.     .           .  .                      //
//    [__]._  _|._. _  _.  \  / _ ._.._  _.__. _.    //
//    |  |[ )(_][  (/,(_]   \/ (/,[  [ )(_] /_(_]    //
//                                                   //
//                                                   //
///////////////////////////////////////////////////////


contract bw is ERC721Creator {
    constructor() ERC721Creator("Manos", "bw") {}
}