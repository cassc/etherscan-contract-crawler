// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bored TLDs
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                               //
//                                                                                                               //
//                                                                                                               //
//                                                                                             dddddddd          //
//    BBBBBBBBBBBBBBBBB                                                                        d::::::d          //
//    B::::::::::::::::B                                                                       d::::::d          //
//    B::::::BBBBBB:::::B                                                                      d::::::d          //
//    BB:::::B     B:::::B                                                                     d:::::d           //
//      B::::B     B:::::B   ooooooooooo   rrrrr   rrrrrrrrr       eeeeeeeeeeee        ddddddddd:::::d           //
//      B::::B     B:::::B oo:::::::::::oo r::::rrr:::::::::r    ee::::::::::::ee    dd::::::::::::::d           //
//      B::::BBBBBB:::::B o:::::::::::::::or:::::::::::::::::r  e::::::eeeee:::::ee d::::::::::::::::d           //
//      B:::::::::::::BB  o:::::ooooo:::::orr::::::rrrrr::::::re::::::e     e:::::ed:::::::ddddd:::::d           //
//      B::::BBBBBB:::::B o::::o     o::::o r:::::r     r:::::re:::::::eeeee::::::ed::::::d    d:::::d           //
//      B::::B     B:::::Bo::::o     o::::o r:::::r     rrrrrrre:::::::::::::::::e d:::::d     d:::::d           //
//      B::::B     B:::::Bo::::o     o::::o r:::::r            e::::::eeeeeeeeeee  d:::::d     d:::::d           //
//      B::::B     B:::::Bo::::o     o::::o r:::::r            e:::::::e           d:::::d     d:::::d           //
//    BB:::::BBBBBB::::::Bo:::::ooooo:::::o r:::::r            e::::::::e          d::::::ddddd::::::dd          //
//    B:::::::::::::::::B o:::::::::::::::o r:::::r             e::::::::eeeeeeee   d:::::::::::::::::d          //
//    B::::::::::::::::B   oo:::::::::::oo  r:::::r              ee:::::::::::::e    d:::::::::ddd::::d          //
//    BBBBBBBBBBBBBBBBB      ooooooooooo    rrrrrrr                eeeeeeeeeeeeee     ddddddddd   ddddd          //
//                                                                                                               //
//    NNNNNNNN        NNNNNNNN                                                                                   //
//    N:::::::N       N::::::N                                                                                   //
//    N::::::::N      N::::::N                                                                                   //
//    N:::::::::N     N::::::N                                                                                   //
//    N::::::::::N    N::::::N  aaaaaaaaaaaaa      mmmmmmm    mmmmmmm       eeeeeeeeeeee        ssssssssss       //
//    N:::::::::::N   N::::::N  a::::::::::::a   mm:::::::m  m:::::::mm   ee::::::::::::ee    ss::::::::::s      //
//    N:::::::N::::N  N::::::N  aaaaaaaaa:::::a m::::::::::mm::::::::::m e::::::eeeee:::::eess:::::::::::::s     //
//    N::::::N N::::N N::::::N           a::::a m::::::::::::::::::::::me::::::e     e:::::es::::::ssss:::::s    //
//    N::::::N  N::::N:::::::N    aaaaaaa:::::a m:::::mmm::::::mmm:::::me:::::::eeeee::::::e s:::::s  ssssss     //
//    N::::::N   N:::::::::::N  aa::::::::::::a m::::m   m::::m   m::::me:::::::::::::::::e    s::::::s          //
//    N::::::N    N::::::::::N a::::aaaa::::::a m::::m   m::::m   m::::me::::::eeeeeeeeeee        s::::::s       //
//    N::::::N     N:::::::::Na::::a    a:::::a m::::m   m::::m   m::::me:::::::e           ssssss   s:::::s     //
//    N::::::N      N::::::::Na::::a    a:::::a m::::m   m::::m   m::::me::::::::e          s:::::ssss::::::s    //
//    N::::::N       N:::::::Na:::::aaaa::::::a m::::m   m::::m   m::::m e::::::::eeeeeeee  s::::::::::::::s     //
//    N::::::N        N::::::N a::::::::::aa:::am::::m   m::::m   m::::m  ee:::::::::::::e   s:::::::::::ss      //
//    NNNNNNNN         NNNNNNN  aaaaaaaaaa  aaaammmmmm   mmmmmm   mmmmmm    eeeeeeeeeeeeee    sssssssssss        //
//                                                                                                               //
//                                                                                                               //
//                                                                                                               //
//                                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract TLD is ERC721Creator {
    constructor() ERC721Creator("Bored TLDs", "TLD") {}
}