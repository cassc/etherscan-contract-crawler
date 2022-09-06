// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Solar Consciousness
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////
//                                                                                 //
//                                                                                 //
//    ::::::::: ...    ::: :::  .      ...       .,:::::::::::::::::: ::   .:      //
//    '`````;;; ;;     ;;; ;;; .;;,..;;;;;;;.    ;;;;'''';;;;;;;;'''',;;   ;;,     //
//        .n[['[['     [[[ [[[[[/' ,[[     \[[,   [[cccc      [[    ,[[[,,,[[[     //
//      ,$$P"  $$      $$$_$$$$,   $$$,     $$$   $$""""      $$    "$$$"""$$$     //
//    ,888bo,_ 88    .d888"888"88o,"888,_ _,88Pd8b888oo,__    88,    888   "88o    //
//     `""*UMM  "YmmMMMM"" MMM "MMP" "YMMMMMP" YMP""""YUMMM   MMM    MMM    YMM    //
//                                                                                 //
//                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////


contract ZUKO is ERC721Creator {
    constructor() ERC721Creator("Solar Consciousness", "ZUKO") {}
}