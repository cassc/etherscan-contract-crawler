// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Cann1bal Editions
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                            //
//                                                                                                                                            //
//                                                                                                                                            //
//                                                                                                                                            //
//                                                                                         bbbbbbbb                                           //
//            CCCCCCCCCCCCC                                                       1111111  b::::::b                              lllllll      //
//         CCC::::::::::::C                                                      1::::::1  b::::::b                              l:::::l      //
//       CC:::::::::::::::C                                                     1:::::::1  b::::::b                              l:::::l      //
//      C:::::CCCCCCCC::::C                                                     111:::::1   b:::::b                              l:::::l      //
//     C:::::C       CCCCCC  aaaaaaaaaaaaa  nnnn  nnnnnnnn    nnnn  nnnnnnnn       1::::1   b:::::bbbbbbbbb      aaaaaaaaaaaaa    l::::l      //
//    C:::::C                a::::::::::::a n:::nn::::::::nn  n:::nn::::::::nn     1::::1   b::::::::::::::bb    a::::::::::::a   l::::l      //
//    C:::::C                aaaaaaaaa:::::an::::::::::::::nn n::::::::::::::nn    1::::1   b::::::::::::::::b   aaaaaaaaa:::::a  l::::l      //
//    C:::::C                         a::::ann:::::::::::::::nnn:::::::::::::::n   1::::l   b:::::bbbbb:::::::b           a::::a  l::::l      //
//    C:::::C                  aaaaaaa:::::a  n:::::nnnn:::::n  n:::::nnnn:::::n   1::::l   b:::::b    b::::::b    aaaaaaa:::::a  l::::l      //
//    C:::::C                aa::::::::::::a  n::::n    n::::n  n::::n    n::::n   1::::l   b:::::b     b:::::b  aa::::::::::::a  l::::l      //
//    C:::::C               a::::aaaa::::::a  n::::n    n::::n  n::::n    n::::n   1::::l   b:::::b     b:::::b a::::aaaa::::::a  l::::l      //
//     C:::::C       CCCCCCa::::a    a:::::a  n::::n    n::::n  n::::n    n::::n   1::::l   b:::::b     b:::::ba::::a    a:::::a  l::::l      //
//      C:::::CCCCCCCC::::Ca::::a    a:::::a  n::::n    n::::n  n::::n    n::::n111::::::111b:::::bbbbbb::::::ba::::a    a:::::a l::::::l     //
//       CC:::::::::::::::Ca:::::aaaa::::::a  n::::n    n::::n  n::::n    n::::n1::::::::::1b::::::::::::::::b a:::::aaaa::::::a l::::::l     //
//         CCC::::::::::::C a::::::::::aa:::a n::::n    n::::n  n::::n    n::::n1::::::::::1b:::::::::::::::b   a::::::::::aa:::al::::::l     //
//            CCCCCCCCCCCCC  aaaaaaaaaa  aaaa nnnnnn    nnnnnn  nnnnnn    nnnnnn111111111111bbbbbbbbbbbbbbbb     aaaaaaaaaa  aaaallllllll     //
//                                      dddddddd                                                                                              //
//    EEEEEEEEEEEEEEEEEEEEEE            d::::::d  iiii          tttt            iiii                                                          //
//    E::::::::::::::::::::E            d::::::d i::::i      ttt:::t           i::::i                                                         //
//    E::::::::::::::::::::E            d::::::d  iiii       t:::::t            iiii                                                          //
//    EE::::::EEEEEEEEE::::E            d:::::d              t:::::t                                                                          //
//      E:::::E       EEEEEE    ddddddddd:::::d iiiiiiittttttt:::::ttttttt    iiiiiii    ooooooooooo   nnnn  nnnnnnnn        ssssssssss       //
//      E:::::E               dd::::::::::::::d i:::::it:::::::::::::::::t    i:::::i  oo:::::::::::oo n:::nn::::::::nn    ss::::::::::s      //
//      E::::::EEEEEEEEEE    d::::::::::::::::d  i::::it:::::::::::::::::t     i::::i o:::::::::::::::on::::::::::::::nn ss:::::::::::::s     //
//      E:::::::::::::::E   d:::::::ddddd:::::d  i::::itttttt:::::::tttttt     i::::i o:::::ooooo:::::onn:::::::::::::::ns::::::ssss:::::s    //
//      E:::::::::::::::E   d::::::d    d:::::d  i::::i      t:::::t           i::::i o::::o     o::::o  n:::::nnnn:::::n s:::::s  ssssss     //
//      E::::::EEEEEEEEEE   d:::::d     d:::::d  i::::i      t:::::t           i::::i o::::o     o::::o  n::::n    n::::n   s::::::s          //
//      E:::::E             d:::::d     d:::::d  i::::i      t:::::t           i::::i o::::o     o::::o  n::::n    n::::n      s::::::s       //
//      E:::::E       EEEEEEd:::::d     d:::::d  i::::i      t:::::t    tttttt i::::i o::::o     o::::o  n::::n    n::::nssssss   s:::::s     //
//    EE::::::EEEEEEEE:::::Ed::::::ddddd::::::ddi::::::i     t::::::tttt:::::ti::::::io:::::ooooo:::::o  n::::n    n::::ns:::::ssss::::::s    //
//    E::::::::::::::::::::E d:::::::::::::::::di::::::i     tt::::::::::::::ti::::::io:::::::::::::::o  n::::n    n::::ns::::::::::::::s     //
//    E::::::::::::::::::::E  d:::::::::ddd::::di::::::i       tt:::::::::::tti::::::i oo:::::::::::oo   n::::n    n::::n s:::::::::::ss      //
//    EEEEEEEEEEEEEEEEEEEEEE   ddddddddd   dddddiiiiiiii         ttttttttttt  iiiiiiii   ooooooooooo     nnnnnn    nnnnnn  sssssssssss        //
//                                                                                                                                            //
//                                                                                                                                            //
//                                                                                                                                            //
//                                                                                                                                            //
//                                                                                                                                            //
//                                                                                                                                            //
//                                                                                                                                            //
//                                                                                                                                            //
//                                                                                                                                            //
//                                                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract Cn1blEdns is ERC1155Creator {
    constructor() ERC1155Creator() {}
}