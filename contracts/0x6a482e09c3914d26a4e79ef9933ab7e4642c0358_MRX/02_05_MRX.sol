// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: IAMTHEMISTERX
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//                                                                                        //
//                                                                                        //
//    MMMMMMMM               MMMMMMMMRRRRRRRRRRRRRRRRR        XXXXXXX       XXXXXXX       //
//    M:::::::M             M:::::::MR::::::::::::::::R       X:::::X       X:::::X       //
//    M::::::::M           M::::::::MR::::::RRRRRR:::::R      X:::::X       X:::::X       //
//    M:::::::::M         M:::::::::MRR:::::R     R:::::R     X::::::X     X::::::X       //
//    M::::::::::M       M::::::::::M  R::::R     R:::::R     XXX:::::X   X:::::XXX       //
//    M:::::::::::M     M:::::::::::M  R::::R     R:::::R        X:::::X X:::::X          //
//    M:::::::M::::M   M::::M:::::::M  R::::RRRRRR:::::R          X:::::X:::::X           //
//    M::::::M M::::M M::::M M::::::M  R:::::::::::::RR            X:::::::::X            //
//    M::::::M  M::::M::::M  M::::::M  R::::RRRRRR:::::R           X:::::::::X            //
//    M::::::M   M:::::::M   M::::::M  R::::R     R:::::R         X:::::X:::::X           //
//    M::::::M    M:::::M    M::::::M  R::::R     R:::::R        X:::::X X:::::X          //
//    M::::::M     MMMMM     M::::::M  R::::R     R:::::R     XXX:::::X   X:::::XXX       //
//    M::::::M               M::::::MRR:::::R     R:::::R     X::::::X     X::::::X       //
//    M::::::M               M::::::MR::::::R     R:::::R     X:::::X       X:::::X       //
//    M::::::M               M::::::MR::::::R     R:::::R     X:::::X       X:::::X       //
//    MMMMMMMM               MMMMMMMMRRRRRRRR     RRRRRRR     XXXXXXX       XXXXXXX       //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract MRX is ERC721Creator {
    constructor() ERC721Creator("IAMTHEMISTERX", "MRX") {}
}