// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Black, White & a Bit of Color
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//                                           //
//      *                      )             //
//     (  `      (       (   ( /(    (       //
//     )\))(     )\    ( )\  )\()) ( )\      //
//    ((_)()\  (((_)   )((_)((_)\  )((_)     //
//    (_()((_) )\___  ((_)_   ((_)((_)_      //
//    |  \/  |((/ __|  | _ ) / _ \ | _ )     //
//    | |\/| | | (__   | _ \| (_) || _ \     //
//    |_|  |_|  \___|  |___/ \___/ |___/     //
//                                           //
//                                           //
///////////////////////////////////////////////


contract MCB is ERC721Creator {
    constructor() ERC721Creator("Black, White & a Bit of Color", "MCB") {}
}