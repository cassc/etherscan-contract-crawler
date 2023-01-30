// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Brain Slug Dance Party
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////
//                                                        //
//                                                        //
//    It's a dancing slug bro, don't read the contract    //
//                                                        //
//                                                        //
////////////////////////////////////////////////////////////


contract BSDP is ERC1155Creator {
    constructor() ERC1155Creator("Brain Slug Dance Party", "BSDP") {}
}