// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SDB SUPER SHOW
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////
//                                 //
//                                 //
//     (   (         (   (         //
//     )\ ))\ )   (  )\ ))\ )      //
//    (()/(()/( ( )\(()/(()/(      //
//     /(_))(_)))((_)/(_))(_))     //
//    (_))(_))_((_)_(_))(_))       //
//    / __||   \| _ ) __/ __|      //
//    \__ \| |) | _ \__ \__ \      //
//    |___/|___/|___/___/___/      //
//                                 //
//                                 //
/////////////////////////////////////


contract SDBSS is ERC1155Creator {
    constructor() ERC1155Creator("SDB SUPER SHOW", "SDBSS") {}
}