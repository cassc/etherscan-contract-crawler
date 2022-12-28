// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Flow
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//                                            //
//    ,------.,--.    ,-----. ,--.   ,--.     //
//    |  .---'|  |   '  .-.  '|  |   |  |     //
//    |  `--, |  |   |  | |  ||  |.'.|  |     //
//    |  |`   |  '--.'  '-'  '|   ,'.   |     //
//    `--'    `-----' `-----' '--'   '--'     //
//                                            //
//                                            //
//                                            //
//                                            //
////////////////////////////////////////////////


contract LJFW is ERC721Creator {
    constructor() ERC721Creator("Flow", "LJFW") {}
}