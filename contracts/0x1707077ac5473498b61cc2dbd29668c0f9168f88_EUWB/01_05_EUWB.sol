// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: I End Up Where I Belong
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                    //
//                                                                                                    //
//    Welcome to my Open Edition called 'I End Up Where I Belong'                                     //
//                                                                                                    //
//    There will be future burn events. Each burn events will lead to another item of my creation.    //
//                                                                                                    //
//    I hope you enjoy my collection. 💀                                                              //
//                                                                                                    //
//                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////


contract EUWB is ERC1155Creator {
    constructor() ERC1155Creator("I End Up Where I Belong", "EUWB") {}
}