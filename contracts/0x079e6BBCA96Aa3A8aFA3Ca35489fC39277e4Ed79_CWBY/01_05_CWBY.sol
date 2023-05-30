// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CWBY Editions
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////
//                                    //
//                                    //
//                                    //
//        )                    )      //
//     ( /(            (    ( /(      //
//     )\())     (     )\   )\())     //
//    ((_)\      )\  (((_) ((_)\      //
//      ((_)  _ ((_) )\___  _((_)     //
//     / _ \ | | | |((/ __|| || |     //
//    | (_) || |_| | | (__ | __ |     //
//     \___/  \___/   \___||_||_|     //
//                                    //
//                                    //
//                                    //
//                                    //
//                                    //
//                                    //
////////////////////////////////////////


contract CWBY is ERC721Creator {
    constructor() ERC721Creator("CWBY Editions", "CWBY") {}
}