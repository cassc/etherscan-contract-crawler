// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Marco Stellisano
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                       //
//                                                                                                                                                                       //
//                                                                                                                                                                       //
//                                                                                                                                                                       //
//                                                                                                                                                                       //
//                    hhhhhhh                                                        tttt                  ffffffffffffffff    iiii  lllllll                             //
//                    h:::::h                                                     ttt:::t                 f::::::::::::::::f  i::::i l:::::l                             //
//                    h:::::h                                                     t:::::t                f::::::::::::::::::f  iiii  l:::::l                             //
//                    h:::::h                                                     t:::::t                f::::::fffffff:::::f        l:::::l                             //
//        ssssssssss   h::::h hhhhh          ooooooooooo      ooooooooooo   ttttttt:::::ttttttt          f:::::f       ffffffiiiiiii  l::::l    mmmmmmm    mmmmmmm       //
//      ss::::::::::s  h::::hh:::::hhh     oo:::::::::::oo  oo:::::::::::oo t:::::::::::::::::t          f:::::f             i:::::i  l::::l  mm:::::::m  m:::::::mm     //
//    ss:::::::::::::s h::::::::::::::hh  o:::::::::::::::oo:::::::::::::::ot:::::::::::::::::t         f:::::::ffffff        i::::i  l::::l m::::::::::mm::::::::::m    //
//    s::::::ssss:::::sh:::::::hhh::::::h o:::::ooooo:::::oo:::::ooooo:::::otttttt:::::::tttttt         f::::::::::::f        i::::i  l::::l m::::::::::::::::::::::m    //
//     s:::::s  ssssss h::::::h   h::::::ho::::o     o::::oo::::o     o::::o      t:::::t               f::::::::::::f        i::::i  l::::l m:::::mmm::::::mmm:::::m    //
//       s::::::s      h:::::h     h:::::ho::::o     o::::oo::::o     o::::o      t:::::t               f:::::::ffffff        i::::i  l::::l m::::m   m::::m   m::::m    //
//          s::::::s   h:::::h     h:::::ho::::o     o::::oo::::o     o::::o      t:::::t                f:::::f              i::::i  l::::l m::::m   m::::m   m::::m    //
//    ssssss   s:::::s h:::::h     h:::::ho::::o     o::::oo::::o     o::::o      t:::::t    tttttt      f:::::f              i::::i  l::::l m::::m   m::::m   m::::m    //
//    s:::::ssss::::::sh:::::h     h:::::ho:::::ooooo:::::oo:::::ooooo:::::o      t::::::tttt:::::t     f:::::::f            i::::::il::::::lm::::m   m::::m   m::::m    //
//    s::::::::::::::s h:::::h     h:::::ho:::::::::::::::oo:::::::::::::::o      tt::::::::::::::t     f:::::::f            i::::::il::::::lm::::m   m::::m   m::::m    //
//     s:::::::::::ss  h:::::h     h:::::h oo:::::::::::oo  oo:::::::::::oo         tt:::::::::::tt     f:::::::f            i::::::il::::::lm::::m   m::::m   m::::m    //
//      sssssssssss    hhhhhhh     hhhhhhh   ooooooooooo      ooooooooooo             ttttttttttt       fffffffff            iiiiiiiillllllllmmmmmm   mmmmmm   mmmmmm    //
//                                                                                                                                                                       //
//                                                                                                                                                                       //
//                                                                                                                                                                       //
//                                                                                                                                                                       //
//                                                                                                                                                                       //
//                                                                                                                                                                       //
//                                                                                                                                                                       //
//                                                                                                                                                                       //
//                                                                                                                                                                       //
//                                                                                                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract STELLA is ERC721Creator {
    constructor() ERC721Creator("Marco Stellisano", "STELLA") {}
}