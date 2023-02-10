// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CheckMan
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                              //
//                                                                                                                                                                              //
//                                                                                                                                                                              //
//                                                                                                                                                                              //
//            CCCCCCCCCCCCChhhhhhh                                                     kkkkkkkk           MMMMMMMM               MMMMMMMM                                       //
//         CCC::::::::::::Ch:::::h                                                     k::::::k           M:::::::M             M:::::::M                                       //
//       CC:::::::::::::::Ch:::::h                                                     k::::::k           M::::::::M           M::::::::M                                       //
//      C:::::CCCCCCCC::::Ch:::::h                                                     k::::::k           M:::::::::M         M:::::::::M                                       //
//     C:::::C       CCCCCC h::::h hhhhh           eeeeeeeeeeee        cccccccccccccccc k:::::k    kkkkkkkM::::::::::M       M::::::::::M  aaaaaaaaaaaaa  nnnn  nnnnnnnn        //
//    C:::::C               h::::hh:::::hhh      ee::::::::::::ee    cc:::::::::::::::c k:::::k   k:::::k M:::::::::::M     M:::::::::::M  a::::::::::::a n:::nn::::::::nn      //
//    C:::::C               h::::::::::::::hh   e::::::eeeee:::::ee c:::::::::::::::::c k:::::k  k:::::k  M:::::::M::::M   M::::M:::::::M  aaaaaaaaa:::::an::::::::::::::nn     //
//    C:::::C               h:::::::hhh::::::h e::::::e     e:::::ec:::::::cccccc:::::c k:::::k k:::::k   M::::::M M::::M M::::M M::::::M           a::::ann:::::::::::::::n    //
//    C:::::C               h::::::h   h::::::he:::::::eeeee::::::ec::::::c     ccccccc k::::::k:::::k    M::::::M  M::::M::::M  M::::::M    aaaaaaa:::::a  n:::::nnnn:::::n    //
//    C:::::C               h:::::h     h:::::he:::::::::::::::::e c:::::c              k:::::::::::k     M::::::M   M:::::::M   M::::::M  aa::::::::::::a  n::::n    n::::n    //
//    C:::::C               h:::::h     h:::::he::::::eeeeeeeeeee  c:::::c              k:::::::::::k     M::::::M    M:::::M    M::::::M a::::aaaa::::::a  n::::n    n::::n    //
//     C:::::C       CCCCCC h:::::h     h:::::he:::::::e           c::::::c     ccccccc k::::::k:::::k    M::::::M     MMMMM     M::::::Ma::::a    a:::::a  n::::n    n::::n    //
//      C:::::CCCCCCCC::::C h:::::h     h:::::he::::::::e          c:::::::cccccc:::::ck::::::k k:::::k   M::::::M               M::::::Ma::::a    a:::::a  n::::n    n::::n    //
//       CC:::::::::::::::C h:::::h     h:::::h e::::::::eeeeeeee   c:::::::::::::::::ck::::::k  k:::::k  M::::::M               M::::::Ma:::::aaaa::::::a  n::::n    n::::n    //
//         CCC::::::::::::C h:::::h     h:::::h  ee:::::::::::::e    cc:::::::::::::::ck::::::k   k:::::k M::::::M               M::::::M a::::::::::aa:::a n::::n    n::::n    //
//            CCCCCCCCCCCCC hhhhhhh     hhhhhhh    eeeeeeeeeeeeee      cccccccccccccccckkkkkkkk    kkkkkkkMMMMMMMM               MMMMMMMM  aaaaaaaaaa  aaaa nnnnnn    nnnnnn    //
//                                                                                                                                                                              //
//                                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CM is ERC1155Creator {
    constructor() ERC1155Creator("CheckMan", "CM") {}
}