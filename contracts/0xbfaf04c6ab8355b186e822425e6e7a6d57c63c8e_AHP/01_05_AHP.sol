// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 55 pictures
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//    hhhhhhh                                                           tttt                                                                     AAA               HHHHHHHHH     HHHHHHHHHPPPPPPPPPPPPPPPPP       //
//    h:::::h                                                        ttt:::t                                                                    A:::A              H:::::::H     H:::::::HP::::::::::::::::P      //
//    h:::::h                                                        t:::::t                                                                   A:::::A             H:::::::H     H:::::::HP::::::PPPPPP:::::P     //
//    h:::::h                                                        t:::::t                                                                  A:::::::A            HH::::::H     H::::::HHPP:::::P     P:::::P    //
//     h::::h hhhhh         aaaaaaaaaaaaa  rrrrr   rrrrrrrrr   ttttttt:::::ttttttt       ooooooooooo                                         A:::::::::A             H:::::H     H:::::H    P::::P     P:::::P    //
//     h::::hh:::::hhh      a::::::::::::a r::::rrr:::::::::r  t:::::::::::::::::t     oo:::::::::::oo                                      A:::::A:::::A            H:::::H     H:::::H    P::::P     P:::::P    //
//     h::::::::::::::hh    aaaaaaaaa:::::ar:::::::::::::::::r t:::::::::::::::::t    o:::::::::::::::o                                    A:::::A A:::::A           H::::::HHHHH::::::H    P::::PPPPPP:::::P     //
//     h:::::::hhh::::::h            a::::arr::::::rrrrr::::::rtttttt:::::::tttttt    o:::::ooooo:::::o      ---------------              A:::::A   A:::::A          H:::::::::::::::::H    P:::::::::::::PP      //
//     h::::::h   h::::::h    aaaaaaa:::::a r:::::r     r:::::r      t:::::t          o::::o     o::::o      -:::::::::::::-             A:::::A     A:::::A         H:::::::::::::::::H    P::::PPPPPPPPP        //
//     h:::::h     h:::::h  aa::::::::::::a r:::::r     rrrrrrr      t:::::t          o::::o     o::::o      ---------------            A:::::AAAAAAAAA:::::A        H::::::HHHHH::::::H    P::::P                //
//     h:::::h     h:::::h a::::aaaa::::::a r:::::r                  t:::::t          o::::o     o::::o                                A:::::::::::::::::::::A       H:::::H     H:::::H    P::::P                //
//     h:::::h     h:::::ha::::a    a:::::a r:::::r                  t:::::t    tttttto::::o     o::::o                               A:::::AAAAAAAAAAAAA:::::A      H:::::H     H:::::H    P::::P                //
//     h:::::h     h:::::ha::::a    a:::::a r:::::r                  t::::::tttt:::::to:::::ooooo:::::o                              A:::::A             A:::::A   HH::::::H     H::::::HHPP::::::PP              //
//     h:::::h     h:::::ha:::::aaaa::::::a r:::::r                  tt::::::::::::::to:::::::::::::::o                             A:::::A               A:::::A  H:::::::H     H:::::::HP::::::::P              //
//     h:::::h     h:::::h a::::::::::aa:::ar:::::r                    tt:::::::::::tt oo:::::::::::oo                             A:::::A                 A:::::A H:::::::H     H:::::::HP::::::::P              //
//     hhhhhhh     hhhhhhh  aaaaaaaaaa  aaaarrrrrrr                      ttttttttttt     ooooooooooo                              AAAAAAA                   AAAAAAAHHHHHHHHH     HHHHHHHHHPPPPPPPPPP              //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract AHP is ERC721Creator {
    constructor() ERC721Creator("55 pictures", "AHP") {}
}