// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Nickolas Tazes' PFP Milady
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////
//                                                               //
//                                                               //
//                                                               //
//                                                               //
//      _                    __  __ ___ _      _   _____   __    //
//     | |_ __ _ ______ ___ |  \/  |_ _| |    /_\ |   \ \ / /    //
//     |  _/ _` |_ / -_|_-< | |\/| || || |__ / _ \| |) \ V /     //
//      \__\__,_/__\___/__/ |_|  |_|___|____/_/ \_\___/ |_|      //
//                                                               //
//                                                               //
//                                                               //
///////////////////////////////////////////////////////////////////


contract PFPTAZESMILADY is ERC721Creator {
    constructor() ERC721Creator("Nickolas Tazes' PFP Milady", "PFPTAZESMILADY") {}
}