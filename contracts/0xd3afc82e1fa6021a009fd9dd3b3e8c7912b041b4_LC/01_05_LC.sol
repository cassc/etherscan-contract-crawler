// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Larva Checks
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                           //
//                                                                                                                                                                                                                                           //
//                                                                                                                                                                                                                                           //
//                                                                                                                                                                                                                                           //
//    LLLLLLLLLLL                                                                                                           CCCCCCCCCCCCChhhhhhh                                                     kkkkkkkk                                //
//    L:::::::::L                                                                                                        CCC::::::::::::Ch:::::h                                                     k::::::k                                //
//    L:::::::::L                                                                                                      CC:::::::::::::::Ch:::::h                                                     k::::::k                                //
//    LL:::::::LL                                                                                                     C:::::CCCCCCCC::::Ch:::::h                                                     k::::::k                                //
//      L:::::L                 aaaaaaaaaaaaa   rrrrr   rrrrrrrrr   vvvvvvv           vvvvvvv  aaaaaaaaaaaaa         C:::::C       CCCCCC h::::h hhhhh           eeeeeeeeeeee        cccccccccccccccc k:::::k    kkkkkkk    ssssssssss       //
//      L:::::L                 a::::::::::::a  r::::rrr:::::::::r   v:::::v         v:::::v   a::::::::::::a       C:::::C               h::::hh:::::hhh      ee::::::::::::ee    cc:::::::::::::::c k:::::k   k:::::k   ss::::::::::s      //
//      L:::::L                 aaaaaaaaa:::::a r:::::::::::::::::r   v:::::v       v:::::v    aaaaaaaaa:::::a      C:::::C               h::::::::::::::hh   e::::::eeeee:::::ee c:::::::::::::::::c k:::::k  k:::::k  ss:::::::::::::s     //
//      L:::::L                          a::::a rr::::::rrrrr::::::r   v:::::v     v:::::v              a::::a      C:::::C               h:::::::hhh::::::h e::::::e     e:::::ec:::::::cccccc:::::c k:::::k k:::::k   s::::::ssss:::::s    //
//      L:::::L                   aaaaaaa:::::a  r:::::r     r:::::r    v:::::v   v:::::v        aaaaaaa:::::a      C:::::C               h::::::h   h::::::he:::::::eeeee::::::ec::::::c     ccccccc k::::::k:::::k     s:::::s  ssssss     //
//      L:::::L                 aa::::::::::::a  r:::::r     rrrrrrr     v:::::v v:::::v       aa::::::::::::a      C:::::C               h:::::h     h:::::he:::::::::::::::::e c:::::c              k:::::::::::k        s::::::s          //
//      L:::::L                a::::aaaa::::::a  r:::::r                  v:::::v:::::v       a::::aaaa::::::a      C:::::C               h:::::h     h:::::he::::::eeeeeeeeeee  c:::::c              k:::::::::::k           s::::::s       //
//      L:::::L         LLLLLLa::::a    a:::::a  r:::::r                   v:::::::::v       a::::a    a:::::a       C:::::C       CCCCCC h:::::h     h:::::he:::::::e           c::::::c     ccccccc k::::::k:::::k    ssssss   s:::::s     //
//    LL:::::::LLLLLLLLL:::::La::::a    a:::::a  r:::::r                    v:::::::v        a::::a    a:::::a        C:::::CCCCCCCC::::C h:::::h     h:::::he::::::::e          c:::::::cccccc:::::ck::::::k k:::::k   s:::::ssss::::::s    //
//    L::::::::::::::::::::::La:::::aaaa::::::a  r:::::r                     v:::::v         a:::::aaaa::::::a         CC:::::::::::::::C h:::::h     h:::::h e::::::::eeeeeeee   c:::::::::::::::::ck::::::k  k:::::k  s::::::::::::::s     //
//    L::::::::::::::::::::::L a::::::::::aa:::a r:::::r                      v:::v           a::::::::::aa:::a          CCC::::::::::::C h:::::h     h:::::h  ee:::::::::::::e    cc:::::::::::::::ck::::::k   k:::::k  s:::::::::::ss      //
//    LLLLLLLLLLLLLLLLLLLLLLLL  aaaaaaaaaa  aaaa rrrrrrr                       vvv             aaaaaaaaaa  aaaa             CCCCCCCCCCCCC hhhhhhh     hhhhhhh    eeeeeeeeeeeeee      cccccccccccccccckkkkkkkk    kkkkkkk  sssssssssss        //
//                                                                                                                                                                                                                                           //
//                                                                                                                                                                                                                                           //
//                                                                                                                                                                                                                                           //
//                                                                                                                                                                                                                                           //
//                                                                                                                                                                                                                                           //
//                                                                                                                                                                                                                                           //
//                                                                                                                                                                                                                                           //
//                                                                                                                                                                                                                                           //
//                                                                                                                                                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract LC is ERC721Creator {
    constructor() ERC721Creator("Larva Checks", "LC") {}
}