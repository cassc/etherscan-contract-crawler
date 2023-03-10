// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SNI Tracing the Wild Uniques
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////
//                                                            //
//                                                            //
//    This dynamic data art project tells the stories of      //
//    predators in the Maasai Mara. Built from data           //
//    reflecting the biosocial interactions of predators      //
//    and human communities in the Mara, these artworks       //
//    show some of the many ways to express the life of       //
//    these rare creatures who are protected by the           //
//    innovative conservation organisation Kenya Wildlife     //
//    Trust. Find out more at https://sni-deep.xyz .          //
//                                                            //
//                                                            //
////////////////////////////////////////////////////////////////


contract TtW is ERC721Creator {
    constructor() ERC721Creator("SNI Tracing the Wild Uniques", "TtW") {}
}