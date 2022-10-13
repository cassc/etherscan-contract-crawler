// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Domestic Situations of Ukrainian Surrealism
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//     _______    ______   __    __   ______      //
//    /       \  /      \ /  |  /  | /      \     //
//    $$$$$$$  |/$$$$$$  |$$ |  $$ |/$$$$$$  |    //
//    $$ |  $$ |$$ \__$$/ $$ |  $$ |$$ \__$$/     //
//    $$ |  $$ |$$      \ $$ |  $$ |$$      \     //
//    $$ |  $$ | $$$$$$  |$$ |  $$ | $$$$$$  |    //
//    $$ |__$$ |/  \__$$ |$$ \__$$ |/  \__$$ |    //
//    $$    $$/ $$    $$/ $$    $$/ $$    $$/     //
//    $$$$$$$/   $$$$$$/   $$$$$$/   $$$$$$/      //
//                                                //
//                                                //
//                                                //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract DSUS is ERC721Creator {
    constructor() ERC721Creator("Domestic Situations of Ukrainian Surrealism", "DSUS") {}
}