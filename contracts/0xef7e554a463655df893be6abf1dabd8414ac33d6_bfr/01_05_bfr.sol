// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Before
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//     _             __                       //
//    | |__    ___  / _|  ___   _ __  ___     //
//    | '_ \  / _ \| |_  / _ \ | '__|/ _ \    //
//    | |_) ||  __/|  _|| (_) || |  |  __/    //
//    |_.__/  \___||_|   \___/ |_|   \___|    //
//                                            //
//                                            //
////////////////////////////////////////////////


contract bfr is ERC721Creator {
    constructor() ERC721Creator("Before", "bfr") {}
}