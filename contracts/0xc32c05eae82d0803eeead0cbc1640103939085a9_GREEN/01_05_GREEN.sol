// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Evergreen
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////
//                                                                 //
//                                                                 //
//                                                                 //
//                                                                 //
//                                                                 //
//         .-.  )   .-..-.  ).--..-.    ).--..-.   .-..  .-.       //
//       ./.-'_(   / ./.-'_/    (   )  /   ./.-'_./.-'_)/   )      //
//       (__.'  \_/  (__.'/      `-/-'/    (__.' (__.''/   (       //
//                             -._/                         `-     //
//                                                                 //
//                                                                 //
//                                                                 //
/////////////////////////////////////////////////////////////////////


contract GREEN is ERC721Creator {
    constructor() ERC721Creator("Evergreen", "GREEN") {}
}