// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NegaBox
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                //
//                                                                                                                                                //
//                                                                                                                                                //
//                                                                                                                                                //
//                                                                                                                                                //
//    NNNNNNNN        NNNNNNNN                                                         BBBBBBBBBBBBBBBBB                                          //
//    N:::::::N       N::::::N                                                         B::::::::::::::::B                                         //
//    N::::::::N      N::::::N                                                         B::::::BBBBBB:::::B                                        //
//    N:::::::::N     N::::::N                                                         BB:::::B     B:::::B                                       //
//    N::::::::::N    N::::::N    eeeeeeeeeeee       ggggggggg   ggggg aaaaaaaaaaaaa     B::::B     B:::::B   ooooooooooo xxxxxxx      xxxxxxx    //
//    N:::::::::::N   N::::::N  ee::::::::::::ee    g:::::::::ggg::::g a::::::::::::a    B::::B     B:::::B oo:::::::::::oox:::::x    x:::::x     //
//    N:::::::N::::N  N::::::N e::::::eeeee:::::ee g:::::::::::::::::g aaaaaaaaa:::::a   B::::BBBBBB:::::B o:::::::::::::::ox:::::x  x:::::x      //
//    N::::::N N::::N N::::::Ne::::::e     e:::::eg::::::ggggg::::::gg          a::::a   B:::::::::::::BB  o:::::ooooo:::::o x:::::xx:::::x       //
//    N::::::N  N::::N:::::::Ne:::::::eeeee::::::eg:::::g     g:::::g    aaaaaaa:::::a   B::::BBBBBB:::::B o::::o     o::::o  x::::::::::x        //
//    N::::::N   N:::::::::::Ne:::::::::::::::::e g:::::g     g:::::g  aa::::::::::::a   B::::B     B:::::Bo::::o     o::::o   x::::::::x         //
//    N::::::N    N::::::::::Ne::::::eeeeeeeeeee  g:::::g     g:::::g a::::aaaa::::::a   B::::B     B:::::Bo::::o     o::::o   x::::::::x         //
//    N::::::N     N:::::::::Ne:::::::e           g::::::g    g:::::ga::::a    a:::::a   B::::B     B:::::Bo::::o     o::::o  x::::::::::x        //
//    N::::::N      N::::::::Ne::::::::e          g:::::::ggggg:::::ga::::a    a:::::a BB:::::BBBBBB::::::Bo:::::ooooo:::::o x:::::xx:::::x       //
//    N::::::N       N:::::::N e::::::::eeeeeeee   g::::::::::::::::ga:::::aaaa::::::a B:::::::::::::::::B o:::::::::::::::ox:::::x  x:::::x      //
//    N::::::N        N::::::N  ee:::::::::::::e    gg::::::::::::::g a::::::::::aa:::aB::::::::::::::::B   oo:::::::::::oox:::::x    x:::::x     //
//    NNNNNNNN         NNNNNNN    eeeeeeeeeeeeee      gggggggg::::::g  aaaaaaaaaa  aaaaBBBBBBBBBBBBBBBBB      ooooooooooo xxxxxxx      xxxxxxx    //
//                                                            g:::::g                                                                             //
//                                                gggggg      g:::::g                                                                             //
//                                                g:::::gg   gg:::::g                                                                             //
//                                                 g::::::ggg:::::::g                                                                             //
//                                                  gg:::::::::::::g                                                                              //
//                                                    ggg::::::ggg                                                                                //
//                                                       gggggg                                                                                   //
//                                                                                                                                                //
//                                                                                                                                                //
//                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract NBOX is ERC721Creator {
    constructor() ERC721Creator("NegaBox", "NBOX") {}
}