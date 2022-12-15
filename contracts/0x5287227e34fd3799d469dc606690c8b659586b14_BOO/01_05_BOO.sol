// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Computers 00
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////
//                                                                              //
//                                                                              //
//                                                                              //
//    KKKKKKKKK    KKKKKKK                                            iiii      //
//    K:::::::K    K:::::K                                           i::::i     //
//    K:::::::K    K:::::K                                            iiii      //
//    K:::::::K   K::::::K                                                      //
//    KK::::::K  K:::::KKK  aaaaaaaaaaaaa      mmmmmmm    mmmmmmm   iiiiiii     //
//      K:::::K K:::::K     a::::::::::::a   mm:::::::m  m:::::::mm i:::::i     //
//      K::::::K:::::K      aaaaaaaaa:::::a m::::::::::mm::::::::::m i::::i     //
//      K:::::::::::K                a::::a m::::::::::::::::::::::m i::::i     //
//      K:::::::::::K         aaaaaaa:::::a m:::::mmm::::::mmm:::::m i::::i     //
//      K::::::K:::::K      aa::::::::::::a m::::m   m::::m   m::::m i::::i     //
//      K:::::K K:::::K    a::::aaaa::::::a m::::m   m::::m   m::::m i::::i     //
//    KK::::::K  K:::::KKKa::::a    a:::::a m::::m   m::::m   m::::m i::::i     //
//    K:::::::K   K::::::Ka::::a    a:::::a m::::m   m::::m   m::::mi::::::i    //
//    K:::::::K    K:::::Ka:::::aaaa::::::a m::::m   m::::m   m::::mi::::::i    //
//    K:::::::K    K:::::K a::::::::::aa:::am::::m   m::::m   m::::mi::::::i    //
//    KKKKKKKKK    KKKKKKK  aaaaaaaaaa  aaaammmmmm   mmmmmm   mmmmmmiiiiiiii    //
//                                                                              //
//                                                                              //
//                                                                              //
//////////////////////////////////////////////////////////////////////////////////


contract BOO is ERC721Creator {
    constructor() ERC721Creator("Computers 00", "BOO") {}
}