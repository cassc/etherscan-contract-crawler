// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BEN.ETH CRYPTO HYPE FACTORY
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//                   )         (        )      //
//       (        ( /(    (    )\ )  ( /(      //
//     ( )\  (    )\())   )\  (()/(  )\())     //
//     )((_) )\  ((_)\  (((_)  /(_))((_)\      //
//    ((_)_ ((_)  _((_) )\___ (_))_| _((_)     //
//     | _ )| __|| \| |((/ __|| |_  | || |     //
//     | _ \| _| | .` | | (__ | __| | __ |     //
//     |___/|___||_|\_|  \___||_|   |_||_|     //
//                                             //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract BENCHF is ERC1155Creator {
    constructor() ERC1155Creator("BEN.ETH CRYPTO HYPE FACTORY", "BENCHF") {}
}