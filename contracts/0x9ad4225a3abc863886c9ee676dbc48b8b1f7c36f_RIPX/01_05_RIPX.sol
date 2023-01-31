// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: RipX
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                                                                            //
//    RRRRRRRRRRRRRRRRR     iiii                     XXXXXXX       XXXXXXX    //
//    R::::::::::::::::R   i::::i                    X:::::X       X:::::X    //
//    R::::::RRRRRR:::::R   iiii                     X:::::X       X:::::X    //
//    RR:::::R     R:::::R                           X::::::X     X::::::X    //
//      R::::R     R:::::Riiiiiiippppp   ppppppppp   XXX:::::X   X:::::XXX    //
//      R::::R     R:::::Ri:::::ip::::ppp:::::::::p     X:::::X X:::::X       //
//      R::::RRRRRR:::::R  i::::ip:::::::::::::::::p     X:::::X:::::X        //
//      R:::::::::::::RR   i::::ipp::::::ppppp::::::p     X:::::::::X         //
//      R::::RRRRRR:::::R  i::::i p:::::p     p:::::p     X:::::::::X         //
//      R::::R     R:::::R i::::i p:::::p     p:::::p    X:::::X:::::X        //
//      R::::R     R:::::R i::::i p:::::p     p:::::p   X:::::X X:::::X       //
//      R::::R     R:::::R i::::i p:::::p    p::::::pXXX:::::X   X:::::XXX    //
//    RR:::::R     R:::::Ri::::::ip:::::ppppp:::::::pX::::::X     X::::::X    //
//    R::::::R     R:::::Ri::::::ip::::::::::::::::p X:::::X       X:::::X    //
//    R::::::R     R:::::Ri::::::ip::::::::::::::pp  X:::::X       X:::::X    //
//    RRRRRRRR     RRRRRRRiiiiiiiip::::::pppppppp    XXXXXXX       XXXXXXX    //
//                                p:::::p                                     //
//                                p:::::p                                     //
//                               p:::::::p                                    //
//                               p:::::::p                                    //
//                               p:::::::p                                    //
//                               ppppppppp                                    //
//                                                                            //
//                                                                            //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////


contract RIPX is ERC1155Creator {
    constructor() ERC1155Creator("RipX", "RIPX") {}
}