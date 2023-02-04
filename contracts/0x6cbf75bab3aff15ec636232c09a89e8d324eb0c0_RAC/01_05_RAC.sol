// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: RASCat
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////
//                               //
//                               //
//      /\___/\                  //
//     ( o   o )                 //
//     (  =^=  )                 //
//     (        )                //
//     (         )               //
//     (          )))))))))))    //
//                               //
//                               //
///////////////////////////////////


contract RAC is ERC1155Creator {
    constructor() ERC1155Creator("RASCat", "RAC") {}
}