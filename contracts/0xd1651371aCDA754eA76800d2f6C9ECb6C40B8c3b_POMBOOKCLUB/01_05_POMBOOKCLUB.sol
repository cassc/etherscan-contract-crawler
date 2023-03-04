// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: POM Book Club
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////
//                                               //
//                                               //
//      ___     __  　　　 _  _                     //
//    (    _  \ / 　  \　 　( 　\/　 )                //
//     )  __/( 　 O 　)　/　 \/　 \                   //
//    (__)   　\__/　 \_)　(_/                      //
//     ___   　　__   　　 __ 　　 __ _                //
//    (  　_ 　\ / 　　 \ 　 /  　　\(  　　　/　 )         //
//     )　 _ 　(( 　 O　 )(  O 　)) 　　　　 　(           //
//    (___/ \__/  \__/(__　\_)                    //
//     　 ___ 　 　__   　　　　　 _ 　 _  　　　___         //
//     / 　__　)(　 　 ) 　　　 　/　 　)　(　 \　( 　 _ 　\    //
//    ( 　(__ 　/ 　　(_/\　) 　　\/　　 ( 　　) 　_ 　(      //
//     \　___)\____/\____/　(___/                  //
//                                               //
//                                               //
//                                               //
///////////////////////////////////////////////////


contract POMBOOKCLUB is ERC721Creator {
    constructor() ERC721Creator("POM Book Club", "POMBOOKCLUB") {}
}