// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 28 Days of Reflections
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////
//                                                                                //
//                                                                                //
//               ^^                   @@@@@@@@@                                   //
//          ^^       ^^            @@@@@@@@@@@@@@@                                //
//                               @@@@@@@@@@@@@@@@@@              ^^               //
//                              @@@@@@@@@@@@@@@@@@@@                              //
//    ~~~~ ~~ ~~~~~ ~~~~~~~~ ~~ &&&&&&&&&&&&&&&&&&&& ~~~~~~~ ~~~~~~~~~~~ ~~~      //
//    ~         ~~   ~  ~       ~~~~~~~~~~~~~~~~~~~~ ~       ~~     ~~ ~          //
//      ~      ~~      ~~ ~~ ~~  ~~~~~~~~~~~~~ ~~~~  ~     ~~~    ~ ~~~  ~ ~~     //
//      ~  ~~     ~         ~      ~~~~~~  ~~ ~~~       ~~ ~ ~~  ~~ ~             //
//    ~  ~       ~ ~      ~           ~~ ~~~~~~  ~      ~~  ~             ~~      //
//          ~             ~        ~      ~      ~~   ~             ~             //
//                                                                                //
//                                                                                //
////////////////////////////////////////////////////////////////////////////////////


contract DOR28 is ERC721Creator {
    constructor() ERC721Creator("28 Days of Reflections", "DOR28") {}
}