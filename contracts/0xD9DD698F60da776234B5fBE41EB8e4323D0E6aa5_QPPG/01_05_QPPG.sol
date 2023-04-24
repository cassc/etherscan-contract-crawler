// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Pablo Guarderas
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                //
//                                                                                                                                                                                //
//                                                                                                                                                                                //
//                                                                                                                                                                                //
//                                       bbbbbbbb                                                                                                                                 //
//    PPPPPPPPPPPPPPPPP                  b::::::b            lllllll                                                                                                              //
//    P::::::::::::::::P                 b::::::b            l:::::l                                                                                                              //
//    P::::::PPPPPP:::::P                b::::::b            l:::::l                                                                                                              //
//    PP:::::P     P:::::P                b:::::b            l:::::l                                                                                                              //
//      P::::P     P:::::Paaaaaaaaaaaaa   b:::::bbbbbbbbb     l::::l    ooooooooooo                                                                                               //
//      P::::P     P:::::Pa::::::::::::a  b::::::::::::::bb   l::::l  oo:::::::::::oo                                                                                             //
//      P::::PPPPPP:::::P aaaaaaaaa:::::a b::::::::::::::::b  l::::l o:::::::::::::::o                                                                                            //
//      P:::::::::::::PP           a::::a b:::::bbbbb:::::::b l::::l o:::::ooooo:::::o                                                                                            //
//      P::::PPPPPPPPP      aaaaaaa:::::a b:::::b    b::::::b l::::l o::::o     o::::o                                                                                            //
//      P::::P            aa::::::::::::a b:::::b     b:::::b l::::l o::::o     o::::o                                                                                            //
//      P::::P           a::::aaaa::::::a b:::::b     b:::::b l::::l o::::o     o::::o                                                                                            //
//      P::::P          a::::a    a:::::a b:::::b     b:::::b l::::l o::::o     o::::o                                                                                            //
//    PP::::::PP        a::::a    a:::::a b:::::bbbbbb::::::bl::::::lo:::::ooooo:::::o                                                                                            //
//    P::::::::P        a:::::aaaa::::::a b::::::::::::::::b l::::::lo:::::::::::::::o                                                                                            //
//    P::::::::P         a::::::::::aa:::ab:::::::::::::::b  l::::::l oo:::::::::::oo                                                                                             //
//    PPPPPPPPPP          aaaaaaaaaa  aaaabbbbbbbbbbbbbbbb   llllllll   ooooooooooo                                                                                               //
//                                                                                                                                                                                //
//                                                                                                                                                                                //
//                                                                                                                                                                                //
//                                                                                                                                                                                //
//                                                                                                                                                                                //
//                                                                                                                                                                                //
//                                                                                                                                                                                //
//                                                                                                                                                                                //
//                                                                                            dddddddd                                                                            //
//            GGGGGGGGGGGGG                                                                   d::::::d                                                                            //
//         GGG::::::::::::G                                                                   d::::::d                                                                            //
//       GG:::::::::::::::G                                                                   d::::::d                                                                            //
//      G:::::GGGGGGGG::::G                                                                   d:::::d                                                                             //
//     G:::::G       GGGGGGuuuuuu    uuuuuu    aaaaaaaaaaaaa  rrrrr   rrrrrrrrr       ddddddddd:::::d     eeeeeeeeeeee    rrrrr   rrrrrrrrr   aaaaaaaaaaaaa      ssssssssss       //
//    G:::::G              u::::u    u::::u    a::::::::::::a r::::rrr:::::::::r    dd::::::::::::::d   ee::::::::::::ee  r::::rrr:::::::::r  a::::::::::::a   ss::::::::::s      //
//    G:::::G              u::::u    u::::u    aaaaaaaaa:::::ar:::::::::::::::::r  d::::::::::::::::d  e::::::eeeee:::::eer:::::::::::::::::r aaaaaaaaa:::::ass:::::::::::::s     //
//    G:::::G    GGGGGGGGGGu::::u    u::::u             a::::arr::::::rrrrr::::::rd:::::::ddddd:::::d e::::::e     e:::::err::::::rrrrr::::::r         a::::as::::::ssss:::::s    //
//    G:::::G    G::::::::Gu::::u    u::::u      aaaaaaa:::::a r:::::r     r:::::rd::::::d    d:::::d e:::::::eeeee::::::e r:::::r     r:::::r  aaaaaaa:::::a s:::::s  ssssss     //
//    G:::::G    GGGGG::::Gu::::u    u::::u    aa::::::::::::a r:::::r     rrrrrrrd:::::d     d:::::d e:::::::::::::::::e  r:::::r     rrrrrrraa::::::::::::a   s::::::s          //
//    G:::::G        G::::Gu::::u    u::::u   a::::aaaa::::::a r:::::r            d:::::d     d:::::d e::::::eeeeeeeeeee   r:::::r           a::::aaaa::::::a      s::::::s       //
//     G:::::G       G::::Gu:::::uuuu:::::u  a::::a    a:::::a r:::::r            d:::::d     d:::::d e:::::::e            r:::::r          a::::a    a:::::assssss   s:::::s     //
//      G:::::GGGGGGGG::::Gu:::::::::::::::uua::::a    a:::::a r:::::r            d::::::ddddd::::::dde::::::::e           r:::::r          a::::a    a:::::as:::::ssss::::::s    //
//       GG:::::::::::::::G u:::::::::::::::ua:::::aaaa::::::a r:::::r             d:::::::::::::::::d e::::::::eeeeeeee   r:::::r          a:::::aaaa::::::as::::::::::::::s     //
//         GGG::::::GGG:::G  uu::::::::uu:::u a::::::::::aa:::ar:::::r              d:::::::::ddd::::d  ee:::::::::::::e   r:::::r           a::::::::::aa:::as:::::::::::ss      //
//            GGGGGG   GGGG    uuuuuuuu  uuuu  aaaaaaaaaa  aaaarrrrrrr               ddddddddd   ddddd    eeeeeeeeeeeeee   rrrrrrr            aaaaaaaaaa  aaaa sssssssssss        //
//                                                                                                                                                                                //
//                                                                                                                                                                                //
//                                                                                                                                                                                //
//                                                                                                                                                                                //
//                                                                                                                                                                                //
//                                                                                                                                                                                //
//                                                                                                                                                                                //
//                                                                                                                                                                                //
//                                                                                                                                                                                //
//                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract QPPG is ERC721Creator {
    constructor() ERC721Creator("Pablo Guarderas", "QPPG") {}
}