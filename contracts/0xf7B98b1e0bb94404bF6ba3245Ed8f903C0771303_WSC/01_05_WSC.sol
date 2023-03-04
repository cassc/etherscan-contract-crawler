// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Wizardsmol Customs
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////
//                          //
//                          //
//          /\              //
//         / *\             //
//        / *  \            //
//      ----------          //
//       | 0   0|           //
//       |______| - Smol    //
//                          //
//                          //
//////////////////////////////


contract WSC is ERC721Creator {
    constructor() ERC721Creator("Wizardsmol Customs", "WSC") {}
}