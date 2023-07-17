// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Poltu PFP
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//     _ _, _ _, _  _, __, ___  _, _,     //
//     | |\/| |\/| / \ |_)  |  /_\ |      //
//     | |  | |  | \ / | \  |  | | | ,    //
//     ~ ~  ~ ~  ~  ~  ~ ~  ~  ~ ~ ~~~    //
//                                        //
//                                        //
////////////////////////////////////////////


contract PPFP is ERC721Creator {
    constructor() ERC721Creator("Poltu PFP", "PPFP") {}
}