// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ZTRL Genesis
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////
//                                           //
//                                           //
//    ___                                    //
//        / / /__  ___/ //   ) )  / /        //
//       / /    / /    //___/ /  / /         //
//      / /    / /    / ___ (   / /          //
//     / /    / /    //   | |  / /           //
//    / /___ / /    //    | | / /____/ /     //
//                                           //
//                                           //
///////////////////////////////////////////////


contract ZGe is ERC721Creator {
    constructor() ERC721Creator("ZTRL Genesis", "ZGe") {}
}