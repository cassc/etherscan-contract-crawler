// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Neko Darumas Specials
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////
//                   //
//                   //
//      —     —      //
//     ———   ———     //
//    ———————————    //
//    ———————————    //
//     —————————     //
//       —————       //
//                   //
//                   //
///////////////////////


contract NDS is ERC1155Creator {
    constructor() ERC1155Creator("Neko Darumas Specials", "NDS") {}
}