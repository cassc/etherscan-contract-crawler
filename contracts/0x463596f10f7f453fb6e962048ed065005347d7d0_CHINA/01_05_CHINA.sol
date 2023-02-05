// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Balloon
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////
//                                             //
//                                             //
//                                             //
//                                             //
//       (         (   (                       //
//     ( )\     )  )\  )\                      //
//     )((_) ( /( ((_)((_) (    (    (         //
//    ((_)_  )(_)) _   _   )\   )\   )\ )      //
//     | _ )((_)_ | | | | ((_) ((_) _(_/(      //
//     | _ \/ _` || | | |/ _ \/ _ \| ' \))     //
//     |___/\__,_||_| |_|\___/\___/|_||_|      //
//                                             //
//                                             //
/////////////////////////////////////////////////


contract CHINA is ERC1155Creator {
    constructor() ERC1155Creator("Balloon", "CHINA") {}
}