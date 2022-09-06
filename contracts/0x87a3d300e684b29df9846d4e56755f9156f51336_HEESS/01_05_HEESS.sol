// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Phoebe Heess
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////
//                        //
//                        //
//          ,--()         //
//      ---'-.------|>    //
//             `--[]      //
//                        //
//                        //
////////////////////////////


contract HEESS is ERC721Creator {
    constructor() ERC721Creator("Phoebe Heess", "HEESS") {}
}