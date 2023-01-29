// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: El Cholo Editions
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////
//                                        //
//                                        //
//                       )                //
//         (      (   ( /(     (          //
//     (   )\     )\  )\())    )\         //
//     )\ ((_)  (((_)((_)\  ( ((_)(       //
//    ((_) _    )\___ _((_) )\ _  )\      //
//    | __| |  ((/ __| || |((_) |((_)     //
//    | _|| |   | (__| __ / _ \ / _ \     //
//    |___|_|    \___|_||_\___/_\___/     //
//                                        //
//                                        //
//                                        //
////////////////////////////////////////////


contract CHOLO is ERC721Creator {
    constructor() ERC721Creator("El Cholo Editions", "CHOLO") {}
}