// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Drops
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////
//                            //
//                            //
//       __                   //
//      /  )                  //
//     /  / __  __ _   _      //
//    /__/_/ (_(_)/_)_/_)_    //
//               /            //
//              '             //
//                            //
//                            //
////////////////////////////////


contract DROPS is ERC1155Creator {
    constructor() ERC1155Creator("Drops", "DROPS") {}
}