// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: YOURSKULL
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                     //
//                                                                                                                                                                                                     //
//                                                                                                                                                                                                     //
//                                                                                                                                                                                                     //
//                                                                                                                                                                                                     //
//    YYYYYYY       YYYYYYY     OOOOOOOOO     UUUUUUUU     UUUUUUUURRRRRRRRRRRRRRRRR      SSSSSSSSSSSSSSS KKKKKKKKK    KKKKKKKUUUUUUUU     UUUUUUUULLLLLLLLLLL             LLLLLLLLLLL                 //
//    Y:::::Y       Y:::::Y   OO:::::::::OO   U::::::U     U::::::UR::::::::::::::::R   SS:::::::::::::::SK:::::::K    K:::::KU::::::U     U::::::UL:::::::::L             L:::::::::L                 //
//    Y:::::Y       Y:::::Y OO:::::::::::::OO U::::::U     U::::::UR::::::RRRRRR:::::R S:::::SSSSSS::::::SK:::::::K    K:::::KU::::::U     U::::::UL:::::::::L             L:::::::::L                 //
//    Y::::::Y     Y::::::YO:::::::OOO:::::::OUU:::::U     U:::::UURR:::::R     R:::::RS:::::S     SSSSSSSK:::::::K   K::::::KUU:::::U     U:::::UULL:::::::LL             LL:::::::LL                 //
//    YYY:::::Y   Y:::::YYYO::::::O   O::::::O U:::::U     U:::::U   R::::R     R:::::RS:::::S            KK::::::K  K:::::KKK U:::::U     U:::::U   L:::::L                 L:::::L                   //
//       Y:::::Y Y:::::Y   O:::::O     O:::::O U:::::D     D:::::U   R::::R     R:::::RS:::::S              K:::::K K:::::K    U:::::D     D:::::U   L:::::L                 L:::::L                   //
//        Y:::::Y:::::Y    O:::::O     O:::::O U:::::D     D:::::U   R::::RRRRRR:::::R  S::::SSSS           K::::::K:::::K     U:::::D     D:::::U   L:::::L                 L:::::L                   //
//         Y:::::::::Y     O:::::O     O:::::O U:::::D     D:::::U   R:::::::::::::RR    SS::::::SSSSS      K:::::::::::K      U:::::D     D:::::U   L:::::L                 L:::::L                   //
//          Y:::::::Y      O:::::O     O:::::O U:::::D     D:::::U   R::::RRRRRR:::::R     SSS::::::::SS    K:::::::::::K      U:::::D     D:::::U   L:::::L                 L:::::L                   //
//           Y:::::Y       O:::::O     O:::::O U:::::D     D:::::U   R::::R     R:::::R       SSSSSS::::S   K::::::K:::::K     U:::::D     D:::::U   L:::::L                 L:::::L                   //
//           Y:::::Y       O:::::O     O:::::O U:::::D     D:::::U   R::::R     R:::::R            S:::::S  K:::::K K:::::K    U:::::D     D:::::U   L:::::L                 L:::::L                   //
//           Y:::::Y       O::::::O   O::::::O U::::::U   U::::::U   R::::R     R:::::R            S:::::SKK::::::K  K:::::KKK U::::::U   U::::::U   L:::::L         LLLLLL  L:::::L         LLLLLL    //
//           Y:::::Y       O:::::::OOO:::::::O U:::::::UUU:::::::U RR:::::R     R:::::RSSSSSSS     S:::::SK:::::::K   K::::::K U:::::::UUU:::::::U LL:::::::LLLLLLLLL:::::LLL:::::::LLLLLLLLL:::::L    //
//        YYYY:::::YYYY     OO:::::::::::::OO   UU:::::::::::::UU  R::::::R     R:::::RS::::::SSSSSS:::::SK:::::::K    K:::::K  UU:::::::::::::UU  L::::::::::::::::::::::LL::::::::::::::::::::::L    //
//        Y:::::::::::Y       OO:::::::::OO       UU:::::::::UU    R::::::R     R:::::RS:::::::::::::::SS K:::::::K    K:::::K    UU:::::::::UU    L::::::::::::::::::::::LL::::::::::::::::::::::L    //
//        YYYYYYYYYYYYY         OOOOOOOOO           UUUUUUUUU      RRRRRRRR     RRRRRRR SSSSSSSSSSSSSSS   KKKKKKKKK    KKKKKKK      UUUUUUUUU      LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL    //
//                                                                                                                                                                                                     //
//                                                                                                                                                                                                     //
//                                                                                                                                                                                                     //
//                                                                                                                                                                                                     //
//                                                                                                                                                                                                     //
//                                                                                                                                                                                                     //
//                                                                                                                                                                                                     //
//                                                                                                                                                                                                     //
//                                                                                                                                                                                                     //
//                                                                                                                                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract YSKL is ERC721Creator {
    constructor() ERC721Creator("YOURSKULL", "YSKL") {}
}