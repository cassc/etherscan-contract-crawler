// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Rebellio: Unveiled Citizen
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//                                         //
//     (                   (     (         //
//     )\ )       (        )\ )  )\ )      //
//    (()/( (   ( )\  (   (()/( (()/(      //
//     /(_)))\  )((_) )\   /(_)) /(_))     //
//    (_)) ((_)((_)_ ((_) (_))  (_))       //
//    | _ \| __|| _ )| __|| |   / __|      //
//    |   /| _| | _ \| _| | |__ \__ \      //
//    |_|_\|___||___/|___||____||___/      //
//                                         //
//                                         //
//                                         //
//                                         //
/////////////////////////////////////////////


contract RUC is ERC721Creator {
    constructor() ERC721Creator("Rebellio: Unveiled Citizen", "RUC") {}
}