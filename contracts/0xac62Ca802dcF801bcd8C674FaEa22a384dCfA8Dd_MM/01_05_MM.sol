// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Marc Maurer
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////
//                        //
//                        //
//    .------..------.    //
//    |M.--. ||M.--. |    //
//    | (\/) || (\/) |    //
//    | :\/: || :\/: |    //
//    | '--'M|| '--'M|    //
//    `------'`------'    //
//                        //
//                        //
////////////////////////////


contract MM is ERC721Creator {
    constructor() ERC721Creator("Marc Maurer", "MM") {}
}