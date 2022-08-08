// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Aiko
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////
//                                                                    //
//                                                                    //
//                                                                    //
//                                                                    //
//                        iiii  kkkkkkkk                              //
//                       i::::i k::::::k                              //
//                        iiii  k::::::k                              //
//                              k::::::k                              //
//      aaaaaaaaaaaaa   iiiiiii  k:::::k    kkkkkkk ooooooooooo       //
//      a::::::::::::a  i:::::i  k:::::k   k:::::koo:::::::::::oo     //
//      aaaaaaaaa:::::a  i::::i  k:::::k  k:::::ko:::::::::::::::o    //
//               a::::a  i::::i  k:::::k k:::::k o:::::ooooo:::::o    //
//        aaaaaaa:::::a  i::::i  k::::::k:::::k  o::::o     o::::o    //
//      aa::::::::::::a  i::::i  k:::::::::::k   o::::o     o::::o    //
//     a::::aaaa::::::a  i::::i  k:::::::::::k   o::::o     o::::o    //
//    a::::a    a:::::a  i::::i  k::::::k:::::k  o::::o     o::::o    //
//    a::::a    a:::::a i::::::ik::::::k k:::::k o:::::ooooo:::::o    //
//    a:::::aaaa::::::a i::::::ik::::::k  k:::::ko:::::::::::::::o    //
//     a::::::::::aa:::ai::::::ik::::::k   k:::::koo:::::::::::oo     //
//      aaaaaaaaaa  aaaaiiiiiiiikkkkkkkk    kkkkkkk ooooooooooo       //
//                                                                    //
//                                                                    //
////////////////////////////////////////////////////////////////////////


contract Aiko is ERC721Creator {
    constructor() ERC721Creator("Aiko", "Aiko") {}
}