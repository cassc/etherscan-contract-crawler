// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Graphicurve
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                    //
//            GGGGGGGGGGGGG                                                      hhhhhhh               iiii                                                                                                           //
//         GGG::::::::::::G                                                      h:::::h              i::::i                                                                                                          //
//       GG:::::::::::::::G                                                      h:::::h               iiii                                                                                                           //
//      G:::::GGGGGGGG::::G                                                      h:::::h                                                                                                                              //
//     G:::::G       GGGGGGrrrrr   rrrrrrrrr   aaaaaaaaaaaaa  ppppp   ppppppppp   h::::h hhhhh       iiiiiii     ccccccccccccccccuuuuuu    uuuuuu rrrrr   rrrrrrrrrvvvvvvv           vvvvvvv eeeeeeeeeeee             //
//    G:::::G              r::::rrr:::::::::r  a::::::::::::a p::::ppp:::::::::p  h::::hh:::::hhh    i:::::i   cc:::::::::::::::cu::::u    u::::u r::::rrr:::::::::rv:::::v         v:::::vee::::::::::::ee           //
//    G:::::G              r:::::::::::::::::r aaaaaaaaa:::::ap:::::::::::::::::p h::::::::::::::hh   i::::i  c:::::::::::::::::cu::::u    u::::u r:::::::::::::::::rv:::::v       v:::::ve::::::eeeee:::::ee         //
//    G:::::G    GGGGGGGGGGrr::::::rrrrr::::::r         a::::app::::::ppppp::::::ph:::::::hhh::::::h  i::::i c:::::::cccccc:::::cu::::u    u::::u rr::::::rrrrr::::::rv:::::v     v:::::ve::::::e     e:::::e         //
//    G:::::G    G::::::::G r:::::r     r:::::r  aaaaaaa:::::a p:::::p     p:::::ph::::::h   h::::::h i::::i c::::::c     cccccccu::::u    u::::u  r:::::r     r:::::r v:::::v   v:::::v e:::::::eeeee::::::e         //
//    G:::::G    GGGGG::::G r:::::r     rrrrrrraa::::::::::::a p:::::p     p:::::ph:::::h     h:::::h i::::i c:::::c             u::::u    u::::u  r:::::r     rrrrrrr  v:::::v v:::::v  e:::::::::::::::::e          //
//    G:::::G        G::::G r:::::r           a::::aaaa::::::a p:::::p     p:::::ph:::::h     h:::::h i::::i c:::::c             u::::u    u::::u  r:::::r               v:::::v:::::v   e::::::eeeeeeeeeee           //
//     G:::::G       G::::G r:::::r          a::::a    a:::::a p:::::p    p::::::ph:::::h     h:::::h i::::i c::::::c     cccccccu:::::uuuu:::::u  r:::::r                v:::::::::v    e:::::::e                    //
//      G:::::GGGGGGGG::::G r:::::r          a::::a    a:::::a p:::::ppppp:::::::ph:::::h     h:::::hi::::::ic:::::::cccccc:::::cu:::::::::::::::uur:::::r                 v:::::::v     e::::::::e                   //
//       GG:::::::::::::::G r:::::r          a:::::aaaa::::::a p::::::::::::::::p h:::::h     h:::::hi::::::i c:::::::::::::::::c u:::::::::::::::ur:::::r                  v:::::v       e::::::::eeeeeeee           //
//         GGG::::::GGG:::G r:::::r           a::::::::::aa:::ap::::::::::::::pp  h:::::h     h:::::hi::::::i  cc:::::::::::::::c  uu::::::::uu:::ur:::::r                   v:::v         ee:::::::::::::e           //
//            GGGGGG   GGGG rrrrrrr            aaaaaaaaaa  aaaap::::::pppppppp    hhhhhhh     hhhhhhhiiiiiiii    cccccccccccccccc    uuuuuuuu  uuuurrrrrrr                    vvv            eeeeeeeeeeeeee           //
//                                                             p:::::p                                                                                                                                                //
//                                                             p:::::p                                                                                                                                                //
//                                                            p:::::::p                                                                                                                                               //
//                                                            p:::::::p                                                                                                                                               //
//                                                            p:::::::p                                                                                                                                               //
//                                                            ppppppppp                                                                                                                                               //
//                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract GC is ERC721Creator {
    constructor() ERC721Creator("Graphicurve", "GC") {}
}