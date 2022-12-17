// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NeoBox
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                            //
//                                                                                                                            //
//                                                                                                                            //
//                                                                                                                            //
//                                                                                                                            //
//    NNNNNNNN        NNNNNNNN                                     BBBBBBBBBBBBBBBBB                                          //
//    N:::::::N       N::::::N                                     B::::::::::::::::B                                         //
//    N::::::::N      N::::::N                                     B::::::BBBBBB:::::B                                        //
//    N:::::::::N     N::::::N                                     BB:::::B     B:::::B                                       //
//    N::::::::::N    N::::::N    eeeeeeeeeeee       ooooooooooo     B::::B     B:::::B   ooooooooooo xxxxxxx      xxxxxxx    //
//    N:::::::::::N   N::::::N  ee::::::::::::ee   oo:::::::::::oo   B::::B     B:::::B oo:::::::::::oox:::::x    x:::::x     //
//    N:::::::N::::N  N::::::N e::::::eeeee:::::eeo:::::::::::::::o  B::::BBBBBB:::::B o:::::::::::::::ox:::::x  x:::::x      //
//    N::::::N N::::N N::::::Ne::::::e     e:::::eo:::::ooooo:::::o  B:::::::::::::BB  o:::::ooooo:::::o x:::::xx:::::x       //
//    N::::::N  N::::N:::::::Ne:::::::eeeee::::::eo::::o     o::::o  B::::BBBBBB:::::B o::::o     o::::o  x::::::::::x        //
//    N::::::N   N:::::::::::Ne:::::::::::::::::e o::::o     o::::o  B::::B     B:::::Bo::::o     o::::o   x::::::::x         //
//    N::::::N    N::::::::::Ne::::::eeeeeeeeeee  o::::o     o::::o  B::::B     B:::::Bo::::o     o::::o   x::::::::x         //
//    N::::::N     N:::::::::Ne:::::::e           o::::o     o::::o  B::::B     B:::::Bo::::o     o::::o  x::::::::::x        //
//    N::::::N      N::::::::Ne::::::::e          o:::::ooooo:::::oBB:::::BBBBBB::::::Bo:::::ooooo:::::o x:::::xx:::::x       //
//    N::::::N       N:::::::N e::::::::eeeeeeee  o:::::::::::::::oB:::::::::::::::::B o:::::::::::::::ox:::::x  x:::::x      //
//    N::::::N        N::::::N  ee:::::::::::::e   oo:::::::::::oo B::::::::::::::::B   oo:::::::::::oox:::::x    x:::::x     //
//    NNNNNNNN         NNNNNNN    eeeeeeeeeeeeee     ooooooooooo   BBBBBBBBBBBBBBBBB      ooooooooooo xxxxxxx      xxxxxxx    //
//                                                                                                                            //
//                                                                                                                            //
//                                                                                                                            //
//                                                                                                                            //
//                                                                                                                            //
//                                                                                                                            //
//                                                                                                                            //
//                                                                                                                            //
//                                                                                                                            //
//                                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract NeoBox is ERC721Creator {
    constructor() ERC721Creator("NeoBox", "NeoBox") {}
}