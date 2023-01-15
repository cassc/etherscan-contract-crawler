// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PRIVATE PLACE
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                 //
//                                                                                                                                                                                                 //
//                                                                                                                                                                                                 //
//                                                                                                                                                                                                 //
//                                                                                                                                                                                                 //
//    NNNNNNNN        NNNNNNNN                          tttt                            lllllll   iiii                           VVVVVVVV           VVVVVVVVIIIIIIIIIIPPPPPPPPPPPPPPPPP            //
//    N:::::::N       N::::::N                       ttt:::t                            l:::::l  i::::i                          V::::::V           V::::::VI::::::::IP::::::::::::::::P           //
//    N::::::::N      N::::::N                       t:::::t                            l:::::l   iiii                           V::::::V           V::::::VI::::::::IP::::::PPPPPP:::::P          //
//    N:::::::::N     N::::::N                       t:::::t                            l:::::l                                  V::::::V           V::::::VII::::::IIPP:::::P     P:::::P         //
//    N::::::::::N    N::::::N  aaaaaaaaaaaaa  ttttttt:::::ttttttt      aaaaaaaaaaaaa    l::::l iiiiiii     eeeeeeeeeeee          V:::::V           V:::::V   I::::I    P::::P     P:::::P         //
//    N:::::::::::N   N::::::N  a::::::::::::a t:::::::::::::::::t      a::::::::::::a   l::::l i:::::i   ee::::::::::::ee         V:::::V         V:::::V    I::::I    P::::P     P:::::P         //
//    N:::::::N::::N  N::::::N  aaaaaaaaa:::::at:::::::::::::::::t      aaaaaaaaa:::::a  l::::l  i::::i  e::::::eeeee:::::ee        V:::::V       V:::::V     I::::I    P::::PPPPPP:::::P          //
//    N::::::N N::::N N::::::N           a::::atttttt:::::::tttttt               a::::a  l::::l  i::::i e::::::e     e:::::e         V:::::V     V:::::V      I::::I    P:::::::::::::PP           //
//    N::::::N  N::::N:::::::N    aaaaaaa:::::a      t:::::t              aaaaaaa:::::a  l::::l  i::::i e:::::::eeeee::::::e          V:::::V   V:::::V       I::::I    P::::PPPPPPPPP             //
//    N::::::N   N:::::::::::N  aa::::::::::::a      t:::::t            aa::::::::::::a  l::::l  i::::i e:::::::::::::::::e            V:::::V V:::::V        I::::I    P::::P                     //
//    N::::::N    N::::::::::N a::::aaaa::::::a      t:::::t           a::::aaaa::::::a  l::::l  i::::i e::::::eeeeeeeeeee              V:::::V:::::V         I::::I    P::::P                     //
//    N::::::N     N:::::::::Na::::a    a:::::a      t:::::t    tttttta::::a    a:::::a  l::::l  i::::i e:::::::e                        V:::::::::V          I::::I    P::::P                     //
//    N::::::N      N::::::::Na::::a    a:::::a      t::::::tttt:::::ta::::a    a:::::a l::::::li::::::ie::::::::e                        V:::::::V         II::::::IIPP::::::PP                   //
//    N::::::N       N:::::::Na:::::aaaa::::::a      tt::::::::::::::ta:::::aaaa::::::a l::::::li::::::i e::::::::eeeeeeee                 V:::::V          I::::::::IP::::::::P                   //
//    N::::::N        N::::::N a::::::::::aa:::a       tt:::::::::::tt a::::::::::aa:::al::::::li::::::i  ee:::::::::::::e                  V:::V           I::::::::IP::::::::P                   //
//    NNNNNNNN         NNNNNNN  aaaaaaaaaa  aaaa         ttttttttttt    aaaaaaaaaa  aaaalllllllliiiiiiii    eeeeeeeeeeeeee                   VVV            IIIIIIIIIIPPPPPPPPPP                   //
//                                                                                                                                                                                                 //
//                                                                                                                                                                                                 //
//                                                                                                                                                                                                 //
//                                                                                                                                                                                                 //
//                                                                                                                                                                                                 //
//                                                                                                                                                                                                 //
//                                                                                                                                                                                                 //
//                                                                                                                                                                                                 //
//                                                                                                                                                                                                 //
//                                                                                                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract VIP is ERC1155Creator {
    constructor() ERC1155Creator("PRIVATE PLACE", "VIP") {}
}