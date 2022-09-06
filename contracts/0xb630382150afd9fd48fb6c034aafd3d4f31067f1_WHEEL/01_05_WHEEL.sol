// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: As The Wheel Turns Collection
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////
//                                                                           //
//                                                                           //
//                                      ,ood8888booo,                        //
//                                  ,od8           8bo,                      //
//                               ,od                   bo,                   //
//                             ,d8                       8b,                 //
//                            ,o                           o,    ,a8b        //
//                           ,8                             8,,od8  8        //
//                           8'                             d8'     8b       //
//                           8                           d8'ba     aP'       //
//                           Y,                       o8'         aP'        //
//                            Y8,                      YaaaP'    ba          //
//                             Y8o                   Y8'         88          //
//                              `Y8               ,8"           `P           //
//                                Y8o        ,d8P'              ba           //
//                           ooood8888888P"""'                  P'           //
//                        ,od                                  8             //
//                     ,dP     o88o                           o'             //
//                    ,dP          8                          8              //
//                   ,d'   oo       8                       ,8               //
//                   $    d$"8      8           Y    Y  o   8                //
//                  d    d  d8    od  ""boooooooob   d"" 8   8               //
//                  $    8  d   ood' ,   8        b  8   '8  b               //
//                  $   $  8  8     d  d8        `b  d    '8  b              //
//                   $  $ 8   b    Y  d8          8 ,P     '8  b             //
//                   `$$  Yb  b     8b 8b         8 8,      '8  o,           //
//                        `Y  b      8o  $$o      d  b        b   $o         //
//                         8   '$     8$,,$"      $   $o      '$o$$          //
//                         $o$$P"                 $$o$                       //
//                                                                           //
//    WolF Mercury Photography -  As The Wheel Turns Collection              //
//                                                                           //
//                                                                           //
///////////////////////////////////////////////////////////////////////////////


contract WHEEL is ERC721Creator {
    constructor() ERC721Creator("As The Wheel Turns Collection", "WHEEL") {}
}