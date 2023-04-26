// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pretty girl and her soft friend
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////
//                                       //
//                                       //
//    ///////////////////////////////    //
//    Pretty girl                        //
//    ///////////////////////////////    //
//                                       //
//                                       //
///////////////////////////////////////////


contract Prettygirl is ERC721Creator {
    constructor() ERC721Creator("Pretty girl and her soft friend", "Prettygirl") {}
}