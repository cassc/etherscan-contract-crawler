// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Good Times Club
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////
//                                            //
//                                            //
//      ___                          ___      //
//     (o o)      Free Drops        (o o)     //
//    (  V  )   Good Times Club    (  V  )    //
//    --m-m--------------------------m-m--    //
//                                            //
//                                            //
////////////////////////////////////////////////


contract GTC is ERC1155Creator {
    constructor() ERC1155Creator("Good Times Club", "GTC") {}
}