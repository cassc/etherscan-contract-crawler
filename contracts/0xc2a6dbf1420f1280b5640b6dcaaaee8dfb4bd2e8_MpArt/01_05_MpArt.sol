// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MoonPepesArt
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                          //
//                                                                                                                                                                                                                                                                          //
//                                                                                                                                                                                                                                                                          //
//                                                                                                                                                                                                                                                                          //
//    MMMMMMMM               MMMMMMMM                                                    PPPPPPPPPPPPPPPPP                                                                                                  AAA                                           tttt              //
//    M:::::::M             M:::::::M                                                    P::::::::::::::::P                                                                                                A:::A                                       ttt:::t              //
//    M::::::::M           M::::::::M                                                    P::::::PPPPPP:::::P                                                                                              A:::::A                                      t:::::t              //
//    M:::::::::M         M:::::::::M                                                    PP:::::P     P:::::P                                                                                            A:::::::A                                     t:::::t              //
//    M::::::::::M       M::::::::::M   ooooooooooo      ooooooooooo   nnnn  nnnnnnnn      P::::P     P:::::P  eeeeeeeeeeee    ppppp   ppppppppp       eeeeeeeeeeee        ssssssssss                   A:::::::::A          rrrrr   rrrrrrrrr   ttttttt:::::ttttttt        //
//    M:::::::::::M     M:::::::::::M oo:::::::::::oo  oo:::::::::::oo n:::nn::::::::nn    P::::P     P:::::Pee::::::::::::ee  p::::ppp:::::::::p    ee::::::::::::ee    ss::::::::::s                 A:::::A:::::A         r::::rrr:::::::::r  t:::::::::::::::::t        //
//    M:::::::M::::M   M::::M:::::::Mo:::::::::::::::oo:::::::::::::::on::::::::::::::nn   P::::PPPPPP:::::Pe::::::eeeee:::::eep:::::::::::::::::p  e::::::eeeee:::::eess:::::::::::::s               A:::::A A:::::A        r:::::::::::::::::r t:::::::::::::::::t        //
//    M::::::M M::::M M::::M M::::::Mo:::::ooooo:::::oo:::::ooooo:::::onn:::::::::::::::n  P:::::::::::::PPe::::::e     e:::::epp::::::ppppp::::::pe::::::e     e:::::es::::::ssss:::::s             A:::::A   A:::::A       rr::::::rrrrr::::::rtttttt:::::::tttttt        //
//    M::::::M  M::::M::::M  M::::::Mo::::o     o::::oo::::o     o::::o  n:::::nnnn:::::n  P::::PPPPPPPPP  e:::::::eeeee::::::e p:::::p     p:::::pe:::::::eeeee::::::e s:::::s  ssssss             A:::::A     A:::::A       r:::::r     r:::::r      t:::::t              //
//    M::::::M   M:::::::M   M::::::Mo::::o     o::::oo::::o     o::::o  n::::n    n::::n  P::::P          e:::::::::::::::::e  p:::::p     p:::::pe:::::::::::::::::e    s::::::s                 A:::::AAAAAAAAA:::::A      r:::::r     rrrrrrr      t:::::t              //
//    M::::::M    M:::::M    M::::::Mo::::o     o::::oo::::o     o::::o  n::::n    n::::n  P::::P          e::::::eeeeeeeeeee   p:::::p     p:::::pe::::::eeeeeeeeeee        s::::::s             A:::::::::::::::::::::A     r:::::r                  t:::::t              //
//    M::::::M     MMMMM     M::::::Mo::::o     o::::oo::::o     o::::o  n::::n    n::::n  P::::P          e:::::::e            p:::::p    p::::::pe:::::::e           ssssss   s:::::s          A:::::AAAAAAAAAAAAA:::::A    r:::::r                  t:::::t    tttttt    //
//    M::::::M               M::::::Mo:::::ooooo:::::oo:::::ooooo:::::o  n::::n    n::::nPP::::::PP        e::::::::e           p:::::ppppp:::::::pe::::::::e          s:::::ssss::::::s        A:::::A             A:::::A   r:::::r                  t::::::tttt:::::t    //
//    M::::::M               M::::::Mo:::::::::::::::oo:::::::::::::::o  n::::n    n::::nP::::::::P         e::::::::eeeeeeee   p::::::::::::::::p  e::::::::eeeeeeee  s::::::::::::::s        A:::::A               A:::::A  r:::::r                  tt::::::::::::::t    //
//    M::::::M               M::::::M oo:::::::::::oo  oo:::::::::::oo   n::::n    n::::nP::::::::P          ee:::::::::::::e   p::::::::::::::pp    ee:::::::::::::e   s:::::::::::ss        A:::::A                 A:::::A r:::::r                    tt:::::::::::tt    //
//    MMMMMMMM               MMMMMMMM   ooooooooooo      ooooooooooo     nnnnnn    nnnnnnPPPPPPPPPP            eeeeeeeeeeeeee   p::::::pppppppp        eeeeeeeeeeeeee    sssssssssss         AAAAAAA                   AAAAAAArrrrrrr                      ttttttttttt      //
//                                                                                                                              p:::::p                                                                                                                                     //
//                                                                                                                              p:::::p                                                                                                                                     //
//                                                                                                                             p:::::::p                                                                                                                                    //
//                                                                                                                             p:::::::p                                                                                                                                    //
//                                                                                                                             p:::::::p                                                                                                                                    //
//                                                                                                                             ppppppppp                                                                                                                                    //
//                                                                                                                                                                                                                                                                          //
//                                                                                                                                                                                                                                                                          //
//                                                                                                                                                                                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MpArt is ERC1155Creator {
    constructor() ERC1155Creator("MoonPepesArt", "MpArt") {}
}