// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: KHUDA
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                      //
//                                                                                                      //
//                                                                                                      //
//                                                                                                      //
//    bbbbbbbb                                                                              dddddddd    //
//    b::::::b           hhhhhhh                                                            d::::::d    //
//    b::::::b           h:::::h                                                            d::::::d    //
//    b::::::b           h:::::h                                                            d::::::d    //
//     b:::::b           h:::::h                                                            d:::::d     //
//     b:::::bbbbbbbbb    h::::h hhhhh         aaaaaaaaaaaaa  nnnn  nnnnnnnn        ddddddddd:::::d     //
//     b::::::::::::::bb  h::::hh:::::hhh      a::::::::::::a n:::nn::::::::nn    dd::::::::::::::d     //
//     b::::::::::::::::b h::::::::::::::hh    aaaaaaaaa:::::an::::::::::::::nn  d::::::::::::::::d     //
//     b:::::bbbbb:::::::bh:::::::hhh::::::h            a::::ann:::::::::::::::nd:::::::ddddd:::::d     //
//     b:::::b    b::::::bh::::::h   h::::::h    aaaaaaa:::::a  n:::::nnnn:::::nd::::::d    d:::::d     //
//     b:::::b     b:::::bh:::::h     h:::::h  aa::::::::::::a  n::::n    n::::nd:::::d     d:::::d     //
//     b:::::b     b:::::bh:::::h     h:::::h a::::aaaa::::::a  n::::n    n::::nd:::::d     d:::::d     //
//     b:::::b     b:::::bh:::::h     h:::::ha::::a    a:::::a  n::::n    n::::nd:::::d     d:::::d     //
//     b:::::bbbbbb::::::bh:::::h     h:::::ha::::a    a:::::a  n::::n    n::::nd::::::ddddd::::::dd    //
//     b::::::::::::::::b h:::::h     h:::::ha:::::aaaa::::::a  n::::n    n::::n d:::::::::::::::::d    //
//     b:::::::::::::::b  h:::::h     h:::::h a::::::::::aa:::a n::::n    n::::n  d:::::::::ddd::::d    //
//     bbbbbbbbbbbbbbbb   hhhhhhh     hhhhhhh  aaaaaaaaaa  aaaa nnnnnn    nnnnnn   ddddddddd   ddddd    //
//                                                                                                      //
//                                                                                                      //
//                                                                                                      //
//                                                                                                      //
//                                                                                                      //
//                                                                                                      //
//                                                                                                      //
//                                                                                                      //
//                                                                                                      //
//                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////


contract KHD is ERC721Creator {
    constructor() ERC721Creator("KHUDA", "KHD") {}
}