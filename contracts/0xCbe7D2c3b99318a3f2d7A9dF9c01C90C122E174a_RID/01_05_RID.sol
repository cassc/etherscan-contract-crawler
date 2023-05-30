// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Rebellio: Citizen ID
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////
//                                         //
//                                         //
//    (                   (     (          //
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


contract RID is ERC1155Creator {
    constructor() ERC1155Creator("Rebellio: Citizen ID", "RID") {}
}