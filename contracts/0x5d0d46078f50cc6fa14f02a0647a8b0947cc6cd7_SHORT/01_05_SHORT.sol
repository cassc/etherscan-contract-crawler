// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Shortcuts to Enlightenment
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                             //
//                                                                                                                             //
//                                                                                                                             //
//                                                                                                                             //
//                       hhhhhhh               iiii  lllllll   iiii                                                            //
//                       h:::::h              i::::i l:::::l  i::::i                                                           //
//                       h:::::h               iiii  l:::::l   iiii                                                            //
//                       h:::::h                     l:::::l                                                                   //
//        cccccccccccccccch::::h hhhhh       iiiiiii  l::::l iiiiiiinnnn  nnnnnnnn       ggggggggg   ggggg   ooooooooooo       //
//      cc:::::::::::::::ch::::hh:::::hhh    i:::::i  l::::l i:::::in:::nn::::::::nn    g:::::::::ggg::::g oo:::::::::::oo     //
//     c:::::::::::::::::ch::::::::::::::hh   i::::i  l::::l  i::::in::::::::::::::nn  g:::::::::::::::::go:::::::::::::::o    //
//    c:::::::cccccc:::::ch:::::::hhh::::::h  i::::i  l::::l  i::::inn:::::::::::::::ng::::::ggggg::::::ggo:::::ooooo:::::o    //
//    c::::::c     ccccccch::::::h   h::::::h i::::i  l::::l  i::::i  n:::::nnnn:::::ng:::::g     g:::::g o::::o     o::::o    //
//    c:::::c             h:::::h     h:::::h i::::i  l::::l  i::::i  n::::n    n::::ng:::::g     g:::::g o::::o     o::::o    //
//    c:::::c             h:::::h     h:::::h i::::i  l::::l  i::::i  n::::n    n::::ng:::::g     g:::::g o::::o     o::::o    //
//    c::::::c     ccccccch:::::h     h:::::h i::::i  l::::l  i::::i  n::::n    n::::ng::::::g    g:::::g o::::o     o::::o    //
//    c:::::::cccccc:::::ch:::::h     h:::::hi::::::il::::::li::::::i n::::n    n::::ng:::::::ggggg:::::g o:::::ooooo:::::o    //
//     c:::::::::::::::::ch:::::h     h:::::hi::::::il::::::li::::::i n::::n    n::::n g::::::::::::::::g o:::::::::::::::o    //
//      cc:::::::::::::::ch:::::h     h:::::hi::::::il::::::li::::::i n::::n    n::::n  gg::::::::::::::g  oo:::::::::::oo     //
//        cccccccccccccccchhhhhhh     hhhhhhhiiiiiiiilllllllliiiiiiii nnnnnn    nnnnnn    gggggggg::::::g    ooooooooooo       //
//                                                                                                g:::::g                      //
//                                                                                    gggggg      g:::::g                      //
//                                                                                    g:::::gg   gg:::::g                      //
//                         pseudonymous art for a decentralized world                  g::::::ggg:::::::g                      //
//                                                                                      gg:::::::::::::g                       //
//                                                                                        ggg::::::ggg                         //
//                                                                                           gggggg                            //
//                                                                                                                             //
//                                                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SHORT is ERC721Creator {
    constructor() ERC721Creator("Shortcuts to Enlightenment", "SHORT") {}
}