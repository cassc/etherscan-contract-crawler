// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Zigmarillion EDs
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                              //
//                                                                                                                                                                                              //
//                                                                                                                                                                                              //
//                                                                                                                                                                                              //
//    ZZZZZZZZZZZZZZZZZZZ  iiii                                                                                      iiii  lllllll lllllll   iiii                   NNNNNNNN        NNNNNNNN    //
//    Z:::::::::::::::::Z i::::i                                                                                    i::::i l:::::l l:::::l  i::::i                  N:::::::N       N::::::N    //
//    Z:::::::::::::::::Z  iiii                                                                                      iiii  l:::::l l:::::l   iiii                   N::::::::N      N::::::N    //
//    Z:::ZZZZZZZZ:::::Z                                                                                                   l:::::l l:::::l                          N:::::::::N     N::::::N    //
//    ZZZZZ     Z:::::Z  iiiiiii    ggggggggg   ggggg   mmmmmmm    mmmmmmm     aaaaaaaaaaaaa   rrrrr   rrrrrrrrr   iiiiiii  l::::l  l::::l iiiiiii    ooooooooooo   N::::::::::N    N::::::N    //
//            Z:::::Z    i:::::i   g:::::::::ggg::::g mm:::::::m  m:::::::mm   a::::::::::::a  r::::rrr:::::::::r  i:::::i  l::::l  l::::l i:::::i  oo:::::::::::oo N:::::::::::N   N::::::N    //
//           Z:::::Z      i::::i  g:::::::::::::::::gm::::::::::mm::::::::::m  aaaaaaaaa:::::a r:::::::::::::::::r  i::::i  l::::l  l::::l  i::::i o:::::::::::::::oN:::::::N::::N  N::::::N    //
//          Z:::::Z       i::::i g::::::ggggg::::::ggm::::::::::::::::::::::m           a::::a rr::::::rrrrr::::::r i::::i  l::::l  l::::l  i::::i o:::::ooooo:::::oN::::::N N::::N N::::::N    //
//         Z:::::Z        i::::i g:::::g     g:::::g m:::::mmm::::::mmm:::::m    aaaaaaa:::::a  r:::::r     r:::::r i::::i  l::::l  l::::l  i::::i o::::o     o::::oN::::::N  N::::N:::::::N    //
//        Z:::::Z         i::::i g:::::g     g:::::g m::::m   m::::m   m::::m  aa::::::::::::a  r:::::r     rrrrrrr i::::i  l::::l  l::::l  i::::i o::::o     o::::oN::::::N   N:::::::::::N    //
//       Z:::::Z          i::::i g:::::g     g:::::g m::::m   m::::m   m::::m a::::aaaa::::::a  r:::::r             i::::i  l::::l  l::::l  i::::i o::::o     o::::oN::::::N    N::::::::::N    //
//    ZZZ:::::Z     ZZZZZ i::::i g::::::g    g:::::g m::::m   m::::m   m::::ma::::a    a:::::a  r:::::r             i::::i  l::::l  l::::l  i::::i o::::o     o::::oN::::::N     N:::::::::N    //
//    Z::::::ZZZZZZZZ:::Zi::::::ig:::::::ggggg:::::g m::::m   m::::m   m::::ma::::a    a:::::a  r:::::r            i::::::il::::::ll::::::li::::::io:::::ooooo:::::oN::::::N      N::::::::N    //
//    Z:::::::::::::::::Zi::::::i g::::::::::::::::g m::::m   m::::m   m::::ma:::::aaaa::::::a  r:::::r            i::::::il::::::ll::::::li::::::io:::::::::::::::oN::::::N       N:::::::N    //
//    Z:::::::::::::::::Zi::::::i  gg::::::::::::::g m::::m   m::::m   m::::m a::::::::::aa:::a r:::::r            i::::::il::::::ll::::::li::::::i oo:::::::::::oo N::::::N        N::::::N    //
//    ZZZZZZZZZZZZZZZZZZZiiiiiiii    gggggggg::::::g mmmmmm   mmmmmm   mmmmmm  aaaaaaaaaa  aaaa rrrrrrr            iiiiiiiilllllllllllllllliiiiiiii   ooooooooooo   NNNNNNNN         NNNNNNN    //
//                                           g:::::g                                                                                                                                            //
//                               gggggg      g:::::g                                                                                                                                            //
//                               g:::::gg   gg:::::g                                                                                                                                            //
//                                g::::::ggg:::::::g                                                                                                                                            //
//                                 gg:::::::::::::g                                                                                                                                             //
//                                   ggg::::::ggg                                                                                                                                               //
//                                      gggggg                                                                                                                                                  //
//                                                                                                                                                                                              //
//                                                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ZigEDs is ERC1155Creator {
    constructor() ERC1155Creator() {}
}