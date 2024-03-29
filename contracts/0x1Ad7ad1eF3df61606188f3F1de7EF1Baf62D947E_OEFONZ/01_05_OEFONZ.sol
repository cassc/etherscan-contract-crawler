// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Editions by Fonz
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                          //
//                                                                                                                                                                                                                                                                                                          //
//                                                                                                                                                                                                                                                                                                          //
//                                                                                                                                                                                                                                                                                                          //
//                                                                                                                                                                                                    dddddddd                                                                                              //
//    FFFFFFFFFFFFFFFFFFFFFF                                                           OOOOOOOOO                                                                    EEEEEEEEEEEEEEEEEEEEEE            d::::::d  iiii          tttt            iiii                                                          //
//    F::::::::::::::::::::F                                                         OO:::::::::OO                                                                  E::::::::::::::::::::E            d::::::d i::::i      ttt:::t           i::::i                                                         //
//    F::::::::::::::::::::F                                                       OO:::::::::::::OO                                                                E::::::::::::::::::::E            d::::::d  iiii       t:::::t            iiii                                                          //
//    FF::::::FFFFFFFFF::::F                                                      O:::::::OOO:::::::O                                                               EE::::::EEEEEEEEE::::E            d:::::d              t:::::t                                                                          //
//      F:::::F       FFFFFFooooooooooo   nnnn  nnnnnnnn    zzzzzzzzzzzzzzzzz     O::::::O   O::::::Oppppp   ppppppppp       eeeeeeeeeeee    nnnn  nnnnnnnn           E:::::E       EEEEEE    ddddddddd:::::d iiiiiiittttttt:::::ttttttt    iiiiiii    ooooooooooo   nnnn  nnnnnnnn        ssssssssss       //
//      F:::::F           oo:::::::::::oo n:::nn::::::::nn  z:::::::::::::::z     O:::::O     O:::::Op::::ppp:::::::::p    ee::::::::::::ee  n:::nn::::::::nn         E:::::E               dd::::::::::::::d i:::::it:::::::::::::::::t    i:::::i  oo:::::::::::oo n:::nn::::::::nn    ss::::::::::s      //
//      F::::::FFFFFFFFFFo:::::::::::::::on::::::::::::::nn z::::::::::::::z      O:::::O     O:::::Op:::::::::::::::::p  e::::::eeeee:::::een::::::::::::::nn        E::::::EEEEEEEEEE    d::::::::::::::::d  i::::it:::::::::::::::::t     i::::i o:::::::::::::::on::::::::::::::nn ss:::::::::::::s     //
//      F:::::::::::::::Fo:::::ooooo:::::onn:::::::::::::::nzzzzzzzz::::::z       O:::::O     O:::::Opp::::::ppppp::::::pe::::::e     e:::::enn:::::::::::::::n       E:::::::::::::::E   d:::::::ddddd:::::d  i::::itttttt:::::::tttttt     i::::i o:::::ooooo:::::onn:::::::::::::::ns::::::ssss:::::s    //
//      F:::::::::::::::Fo::::o     o::::o  n:::::nnnn:::::n      z::::::z        O:::::O     O:::::O p:::::p     p:::::pe:::::::eeeee::::::e  n:::::nnnn:::::n       E:::::::::::::::E   d::::::d    d:::::d  i::::i      t:::::t           i::::i o::::o     o::::o  n:::::nnnn:::::n s:::::s  ssssss     //
//      F::::::FFFFFFFFFFo::::o     o::::o  n::::n    n::::n     z::::::z         O:::::O     O:::::O p:::::p     p:::::pe:::::::::::::::::e   n::::n    n::::n       E::::::EEEEEEEEEE   d:::::d     d:::::d  i::::i      t:::::t           i::::i o::::o     o::::o  n::::n    n::::n   s::::::s          //
//      F:::::F          o::::o     o::::o  n::::n    n::::n    z::::::z          O:::::O     O:::::O p:::::p     p:::::pe::::::eeeeeeeeeee    n::::n    n::::n       E:::::E             d:::::d     d:::::d  i::::i      t:::::t           i::::i o::::o     o::::o  n::::n    n::::n      s::::::s       //
//      F:::::F          o::::o     o::::o  n::::n    n::::n   z::::::z           O::::::O   O::::::O p:::::p    p::::::pe:::::::e             n::::n    n::::n       E:::::E       EEEEEEd:::::d     d:::::d  i::::i      t:::::t    tttttt i::::i o::::o     o::::o  n::::n    n::::nssssss   s:::::s     //
//    FF:::::::FF        o:::::ooooo:::::o  n::::n    n::::n  z::::::zzzzzzzz     O:::::::OOO:::::::O p:::::ppppp:::::::pe::::::::e            n::::n    n::::n     EE::::::EEEEEEEE:::::Ed::::::ddddd::::::ddi::::::i     t::::::tttt:::::ti::::::io:::::ooooo:::::o  n::::n    n::::ns:::::ssss::::::s    //
//    F::::::::FF        o:::::::::::::::o  n::::n    n::::n z::::::::::::::z      OO:::::::::::::OO  p::::::::::::::::p  e::::::::eeeeeeee    n::::n    n::::n     E::::::::::::::::::::E d:::::::::::::::::di::::::i     tt::::::::::::::ti::::::io:::::::::::::::o  n::::n    n::::ns::::::::::::::s     //
//    F::::::::FF         oo:::::::::::oo   n::::n    n::::nz:::::::::::::::z        OO:::::::::OO    p::::::::::::::pp    ee:::::::::::::e    n::::n    n::::n     E::::::::::::::::::::E  d:::::::::ddd::::di::::::i       tt:::::::::::tti::::::i oo:::::::::::oo   n::::n    n::::n s:::::::::::ss      //
//    FFFFFFFFFFF           ooooooooooo     nnnnnn    nnnnnnzzzzzzzzzzzzzzzzz          OOOOOOOOO      p::::::pppppppp        eeeeeeeeeeeeee    nnnnnn    nnnnnn     EEEEEEEEEEEEEEEEEEEEEE   ddddddddd   dddddiiiiiiii         ttttttttttt  iiiiiiii   ooooooooooo     nnnnnn    nnnnnn  sssssssssss        //
//                                                                                                    p:::::p                                                                                                                                                                                               //
//                                                                                                    p:::::p                                                                                                                                                                                               //
//                                                                                                   p:::::::p                                                                                                                                                                                              //
//                                                                                                   p:::::::p                                                                                                                                                                                              //
//                                                                                                   p:::::::p                                                                                                                                                                                              //
//                                                                                                   ppppppppp                                                                                                                                                                                              //
//                                                                                                                                                                                                                                                                                                          //
//                                                                                                                                                                                                                                                                                                          //
//                                                                                                                                                                                                                                                                                                          //
//                                                                                                                                                                                                                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract OEFONZ is ERC721Creator {
    constructor() ERC721Creator("Editions by Fonz", "OEFONZ") {}
}