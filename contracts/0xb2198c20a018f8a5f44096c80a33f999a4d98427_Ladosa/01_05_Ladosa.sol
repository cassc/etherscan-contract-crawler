// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LADOSA
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////
//                                              //
//                                              //
//                                              //
//       __    ___    ___   ____   ____ ___     //
//      / /   / _ |  / _ \ / __ \ / __// _ |    //
//     / /__ / __ | / // // /_/ /_\ \ / __ |    //
//    /____//_/ |_|/____/ \____//___//_/ |_|    //
//                                              //
//                                              //
//                                              //
//                                              //
//////////////////////////////////////////////////


contract Ladosa is ERC721Creator {
    constructor() ERC721Creator("LADOSA", "Ladosa") {}
}