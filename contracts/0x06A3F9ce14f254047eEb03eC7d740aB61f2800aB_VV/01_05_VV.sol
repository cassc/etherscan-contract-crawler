// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Voloshina Vladlena 1/1 art
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                         //
//                                                                                                         //
//     _   _         _                 _                                                                   //
//    ( ) ( )       (_ )              ( )     _                                                            //
//    | | | |   _    | |    _     ___ | |__  (_)  ___     _ _                                              //
//    | | | | /'_`\  | |  /'_`\ /',__)|  _ `\| |/' _ `\ /'_` )                                             //
//    | \_/ |( (_) ) | | ( (_) )\__, \| | | || || ( ) |( (_| |                                             //
//    `\___/'`\___/'(___)`\___/'(____/(_) (_)(_)(_) (_)`\__,_)                                             //
//                                                                                                         //
//     If you buy art on this contract,you can't copy,                                                     //
//      duplicate or use commercial purposes!                                                              //
//                                                                                                         //
//                                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract VV is ERC721Creator {
    constructor() ERC721Creator("Voloshina Vladlena 1/1 art", "VV") {}
}