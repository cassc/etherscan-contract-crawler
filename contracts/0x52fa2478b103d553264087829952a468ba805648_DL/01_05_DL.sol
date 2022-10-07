// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: danileoni
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////
//                        //
//                        //
//    .------..------.    //
//    |2.--. ||3.--. |    //
//    | (\/) || :(): |    //
//    | :\/: || ()() |    //
//    | '--'2|| '--'3|    //
//    `------'`------'    //
//                        //
//                        //
////////////////////////////


contract DL is ERC721Creator {
    constructor() ERC721Creator("danileoni", "DL") {}
}