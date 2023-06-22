// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: James Rush
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////
//                              //
//                              //
//    what is this?             //
//    am i an nft right now?    //
//    are you reading me?       //
//    hi                        //
//                              //
//                              //
//////////////////////////////////


contract JR is ERC721Creator {
    constructor() ERC721Creator("James Rush", "JR") {}
}