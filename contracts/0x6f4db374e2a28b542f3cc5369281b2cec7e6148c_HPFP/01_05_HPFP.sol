// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Harry's PFPs
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//                                             //
//      _              _             _         //
//     | |__  ___  ___| |____      _(_)____    //
//     | '_ \/ __|/ __| '_ \ \ /\ / / |_  /    //
//     | | | \__ \ (__| | | \ V  V /| |/ /     //
//     |_| |_|___/\___|_| |_|\_/\_/ |_/___|    //
//                                             //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract HPFP is ERC721Creator {
    constructor() ERC721Creator("Harry's PFPs", "HPFP") {}
}