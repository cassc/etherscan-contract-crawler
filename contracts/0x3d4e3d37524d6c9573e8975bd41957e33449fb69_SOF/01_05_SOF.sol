// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sofiane's contract
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////
//                                //
//                                //
//                                //
//      _________       _____     //
//     /   _____/ _____/ ____\    //
//     \_____  \ /  _ \   __\     //
//     /        (  <_> )  |       //
//    /_______  /\____/|__|       //
//            \/                  //
//                                //
//                                //
//                                //
////////////////////////////////////


contract SOF is ERC1155Creator {
    constructor() ERC1155Creator("Sofiane's contract", "SOF") {}
}