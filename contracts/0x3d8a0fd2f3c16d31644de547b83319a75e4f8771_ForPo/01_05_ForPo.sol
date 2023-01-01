// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fortune Poems
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                      //
//                                                                                                      //
//    FFFFFFF               tt                              PPPPPP                                      //
//    FF       oooo  rr rr  tt    uu   uu nn nnn    eee     PP   PP  oooo    eee  mm mm mmmm   sss      //
//    FFFF    oo  oo rrr  r tttt  uu   uu nnn  nn ee   e    PPPPPP  oo  oo ee   e mmm  mm  mm s         //
//    FF      oo  oo rr     tt    uu   uu nn   nn eeeee     PP      oo  oo eeeee  mmm  mm  mm  sss      //
//    FF       oooo  rr      tttt  uuuu u nn   nn  eeeee    PP       oooo   eeeee mmm  mm  mm     s     //
//                                                                                             sss      //
//                                                                                                      //
//                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ForPo is ERC721Creator {
    constructor() ERC721Creator("Fortune Poems", "ForPo") {}
}