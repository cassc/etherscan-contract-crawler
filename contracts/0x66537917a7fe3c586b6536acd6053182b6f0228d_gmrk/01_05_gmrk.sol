// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: rothmornings
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////
//                                                       //
//                                                       //
//    / __)( \/ )(  _ \(  / )(  _ \ /  \(_  _)/ )( \     //
//    ( (_ \/ \/ \ )   / )  (  )   /(  O ) )(  ) __ (    //
//     \___/\_)(_/(__\_)(__\_)(__\_) \__/ (__) \_)(_/    //
//                                                       //
//                                                       //
///////////////////////////////////////////////////////////


contract gmrk is ERC721Creator {
    constructor() ERC721Creator("rothmornings", "gmrk") {}
}