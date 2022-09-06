// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PixelArt
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                             //
//                                                                                                                                                                                                                                                                             //
//                                                                                                                                                                                                                                                                             //
//    bbbbbbbb                                                                             dddddddd                                                                                                                                                                            //
//    b::::::b                                                                             d::::::d                                        iiii                                                                                           tttt         hhhhhhh                 //
//    b::::::b                                                                             d::::::d                                       i::::i                                                                                       ttt:::t         h:::::h                 //
//    b::::::b                                                                             d::::::d                                        iiii                                                                                        t:::::t         h:::::h                 //
//     b:::::b                                                                             d:::::d                                                                                                                                     t:::::t         h:::::h                 //
//     b:::::bbbbbbbbb        eeeeeeeeeeee    aaaaaaaaaaaaa  uuuuuu    uuuuuu      ddddddddd:::::d     eeeeeeeeeeee    nnnn  nnnnnnnn    iiiiiii     ssssssssss      ooooooooooo   nnnn  nnnnnnnn                eeeeeeeeeeee    ttttttt:::::ttttttt    h::::h hhhhh           //
//     b::::::::::::::bb    ee::::::::::::ee  a::::::::::::a u::::u    u::::u    dd::::::::::::::d   ee::::::::::::ee  n:::nn::::::::nn  i:::::i   ss::::::::::s   oo:::::::::::oo n:::nn::::::::nn            ee::::::::::::ee  t:::::::::::::::::t    h::::hh:::::hhh        //
//     b::::::::::::::::b  e::::::eeeee:::::eeaaaaaaaaa:::::au::::u    u::::u   d::::::::::::::::d  e::::::eeeee:::::een::::::::::::::nn  i::::i ss:::::::::::::s o:::::::::::::::on::::::::::::::nn          e::::::eeeee:::::eet:::::::::::::::::t    h::::::::::::::hh      //
//     b:::::bbbbb:::::::be::::::e     e:::::e         a::::au::::u    u::::u  d:::::::ddddd:::::d e::::::e     e:::::enn:::::::::::::::n i::::i s::::::ssss:::::so:::::ooooo:::::onn:::::::::::::::n        e::::::e     e:::::etttttt:::::::tttttt    h:::::::hhh::::::h     //
//     b:::::b    b::::::be:::::::eeeee::::::e  aaaaaaa:::::au::::u    u::::u  d::::::d    d:::::d e:::::::eeeee::::::e  n:::::nnnn:::::n i::::i  s:::::s  ssssss o::::o     o::::o  n:::::nnnn:::::n        e:::::::eeeee::::::e      t:::::t          h::::::h   h::::::h    //
//     b:::::b     b:::::be:::::::::::::::::e aa::::::::::::au::::u    u::::u  d:::::d     d:::::d e:::::::::::::::::e   n::::n    n::::n i::::i    s::::::s      o::::o     o::::o  n::::n    n::::n        e:::::::::::::::::e       t:::::t          h:::::h     h:::::h    //
//     b:::::b     b:::::be::::::eeeeeeeeeee a::::aaaa::::::au::::u    u::::u  d:::::d     d:::::d e::::::eeeeeeeeeee    n::::n    n::::n i::::i       s::::::s   o::::o     o::::o  n::::n    n::::n        e::::::eeeeeeeeeee        t:::::t          h:::::h     h:::::h    //
//     b:::::b     b:::::be:::::::e         a::::a    a:::::au:::::uuuu:::::u  d:::::d     d:::::d e:::::::e             n::::n    n::::n i::::i ssssss   s:::::s o::::o     o::::o  n::::n    n::::n        e:::::::e                 t:::::t    tttttth:::::h     h:::::h    //
//     b:::::bbbbbb::::::be::::::::e        a::::a    a:::::au:::::::::::::::uud::::::ddddd::::::dde::::::::e            n::::n    n::::ni::::::is:::::ssss::::::so:::::ooooo:::::o  n::::n    n::::n        e::::::::e                t::::::tttt:::::th:::::h     h:::::h    //
//     b::::::::::::::::b  e::::::::eeeeeeeea:::::aaaa::::::a u:::::::::::::::u d:::::::::::::::::d e::::::::eeeeeeee    n::::n    n::::ni::::::is::::::::::::::s o:::::::::::::::o  n::::n    n::::n ......  e::::::::eeeeeeee        tt::::::::::::::th:::::h     h:::::h    //
//     b:::::::::::::::b    ee:::::::::::::e a::::::::::aa:::a uu::::::::uu:::u  d:::::::::ddd::::d  ee:::::::::::::e    n::::n    n::::ni::::::i s:::::::::::ss   oo:::::::::::oo   n::::n    n::::n .::::.   ee:::::::::::::e          tt:::::::::::tth:::::h     h:::::h    //
//     bbbbbbbbbbbbbbbb       eeeeeeeeeeeeee  aaaaaaaaaa  aaaa   uuuuuuuu  uuuu   ddddddddd   ddddd    eeeeeeeeeeeeee    nnnnnn    nnnnnniiiiiiii  sssssssssss       ooooooooooo     nnnnnn    nnnnnn ......     eeeeeeeeeeeeee            ttttttttttt  hhhhhhh     hhhhhhh    //
//                                                                                                                                                                                                                                                                             //
//                                                                                                                                                                                                                                                                             //
//                                                                                                                                                                                                                                                                             //
//                                                                                                                                                                                                                                                                             //
//                                                                                                                                                                                                                                                                             //
//                                                                                                                                                                                                                                                                             //
//                                                                                                                                                                                                                                                                             //
//                                                                                                                                                                                                                                                                             //
//                                                                                                                                                                                                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PxArt is ERC721Creator {
    constructor() ERC721Creator("PixelArt", "PxArt") {}
}