// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Autumn Effects
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//       *                                  //
//     (  `      (       (           )      //
//     )\))(     )\    ( )\       ( /(      //
//    ((_)()\  (((_)   )((_)  (   )\())     //
//    (_()((_) )\___  ((_)_   )\ ((_)\      //
//    |  \/  |((/ __|  | _ ) ((_)| |(_)     //
//    | |\/| | | (__   | _ \/ _ \| '_ \     //
//    |_|  |_|  \___|  |___/\___/|_.__/     //
//                                          //
//                                          //
//                                          //
//////////////////////////////////////////////


contract MCB is ERC721Creator {
    constructor() ERC721Creator("Autumn Effects", "MCB") {}
}