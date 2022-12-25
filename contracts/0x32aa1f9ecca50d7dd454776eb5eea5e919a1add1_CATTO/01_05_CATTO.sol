// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CATTO
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////
//                         //
//                         //
//        /\_____/\        //
//       /  o   o  \       //
//      ( ==  ^  == )      //
//       )         (       //
//      (           )      //
//     ( (  )   (  ) )     //
//    (__(__)___(__)__)    //
//                         //
//                         //
/////////////////////////////


contract CATTO is ERC1155Creator {
    constructor() ERC1155Creator("CATTO", "CATTO") {}
}