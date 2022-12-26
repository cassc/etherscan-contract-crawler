// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: pravijn
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                    iiii   jjjj                       //
//                                                                                   i::::i j::::j                      //
//                                                                                    iiii   jjjj                       //
//                                                                                                                      //
//    ppppp   ppppppppp   rrrrr   rrrrrrrrr   aaaaaaaaaaaaavvvvvvv           vvvvvvviiiiiiijjjjjjjnnnn  nnnnnnnn        //
//    p::::ppp:::::::::p  r::::rrr:::::::::r  a::::::::::::av:::::v         v:::::v i:::::ij:::::jn:::nn::::::::nn      //
//    p:::::::::::::::::p r:::::::::::::::::r aaaaaaaaa:::::av:::::v       v:::::v   i::::i j::::jn::::::::::::::nn     //
//    pp::::::ppppp::::::prr::::::rrrrr::::::r         a::::a v:::::v     v:::::v    i::::i j::::jnn:::::::::::::::n    //
//     p:::::p     p:::::p r:::::r     r:::::r  aaaaaaa:::::a  v:::::v   v:::::v     i::::i j::::j  n:::::nnnn:::::n    //
//     p:::::p     p:::::p r:::::r     rrrrrrraa::::::::::::a   v:::::v v:::::v      i::::i j::::j  n::::n    n::::n    //
//     p:::::p     p:::::p r:::::r           a::::aaaa::::::a    v:::::v:::::v       i::::i j::::j  n::::n    n::::n    //
//     p:::::p    p::::::p r:::::r          a::::a    a:::::a     v:::::::::v        i::::i j::::j  n::::n    n::::n    //
//     p:::::ppppp:::::::p r:::::r          a::::a    a:::::a      v:::::::v        i::::::ij::::j  n::::n    n::::n    //
//     p::::::::::::::::p  r:::::r          a:::::aaaa::::::a       v:::::v         i::::::ij::::j  n::::n    n::::n    //
//     p::::::::::::::pp   r:::::r           a::::::::::aa:::a       v:::v          i::::::ij::::j  n::::n    n::::n    //
//     p::::::pppppppp     rrrrrrr            aaaaaaaaaa  aaaa        vvv           iiiiiiiij::::j  nnnnnn    nnnnnn    //
//     p:::::p                                                                              j::::j                      //
//     p:::::p                                                                    jjjj      j::::j                      //
//    p:::::::p                                                                  j::::jj   j:::::j                      //
//    p:::::::p                                                                  j::::::jjj::::::j                      //
//    p:::::::p                                                                   jj::::::::::::j                       //
//    ppppppppp                                                                     jjj::::::jjj                        //
//                                                                                     jjjjjj                           //
//                                                                                                                      //
//                                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract prvn is ERC721Creator {
    constructor() ERC721Creator("pravijn", "prvn") {}
}