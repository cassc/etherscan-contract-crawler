// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SeaToonz Rare Discoveries
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////
//                                                           //
//                                                           //
//     ___                _____                              //
//    (  _`\             (_   _)                             //
//    | (_(_)   __     _ _ | |   _      _     ___   ____     //
//    `\__ \  /'__`\ /'_` )| | /'_`\  /'_`\ /' _ `\(_  ,)    //
//    ( )_) |(  ___/( (_| || |( (_) )( (_) )| ( ) | /'/_     //
//    `\____)`\____)`\__,_)(_)`\___/'`\___/'(_) (_)(____)    //
//                                                           //
//                                                           //
//                                                           //
//                                                           //
///////////////////////////////////////////////////////////////


contract SEATNZ is ERC721Creator {
    constructor() ERC721Creator("SeaToonz Rare Discoveries", "SEATNZ") {}
}