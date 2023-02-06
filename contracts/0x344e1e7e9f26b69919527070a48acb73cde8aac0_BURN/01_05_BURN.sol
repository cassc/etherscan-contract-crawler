// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Checks - Burn Edition
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////
//                              //
//                              //
//                              //
//                              //
//       (                      //
//     ( )\   (  (              //
//     )((_) ))\ )(   (         //
//    ((_)_ /((_|()\  )\ )      //
//     | _ |_))( ((_)_(_/(      //
//     | _ \ || | '_| ' \))     //
//     |___/\_,_|_| |_||_|      //
//                              //
//                              //
//                              //
//                              //
//////////////////////////////////


contract BURN is ERC1155Creator {
    constructor() ERC1155Creator("Checks - Burn Edition", "BURN") {}
}