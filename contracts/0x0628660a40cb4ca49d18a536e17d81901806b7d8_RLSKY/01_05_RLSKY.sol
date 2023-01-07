// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: rvlsky
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////
//                                          //
//                                          //
//    :::====  :::===  :::  === ::: ===     //
//     :::  === :::     ::: ===  ::: ===    //
//     =======   =====  ======    =====     //
//     === ===      === === ===    ===      //
//     ===  === ======  ===  ===   ===      //
//                                          //
//                                          //
//                                          //
//////////////////////////////////////////////


contract RLSKY is ERC721Creator {
    constructor() ERC721Creator("rvlsky", "RLSKY") {}
}