// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bird Gang 2023
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                           //
//                                                                                                                                                                                                                                                           //
//                                                                                                                                                                                                                                                           //
//                                                                                                                                                                                                                                                           //
//                                                                                                                                                                                                                                                           //
//    BBBBBBBBBBBBBBBBB   IIIIIIIIIIRRRRRRRRRRRRRRRRR   DDDDDDDDDDDDD                     GGGGGGGGGGGGG               AAA               NNNNNNNN        NNNNNNNN        GGGGGGGGGGGGG     LLLLLLLLLLL     VVVVVVVV           VVVVVVVVIIIIIIIIIIIIIIIIIIII    //
//    B::::::::::::::::B  I::::::::IR::::::::::::::::R  D::::::::::::DDD               GGG::::::::::::G              A:::A              N:::::::N       N::::::N     GGG::::::::::::G     L:::::::::L     V::::::V           V::::::VI::::::::II::::::::I    //
//    B::::::BBBBBB:::::B I::::::::IR::::::RRRRRR:::::R D:::::::::::::::DD           GG:::::::::::::::G             A:::::A             N::::::::N      N::::::N   GG:::::::::::::::G     L:::::::::L     V::::::V           V::::::VI::::::::II::::::::I    //
//    BB:::::B     B:::::BII::::::IIRR:::::R     R:::::RDDD:::::DDDDD:::::D         G:::::GGGGGGGG::::G            A:::::::A            N:::::::::N     N::::::N  G:::::GGGGGGGG::::G     LL:::::::LL     V::::::V           V::::::VII::::::IIII::::::II    //
//      B::::B     B:::::B  I::::I    R::::R     R:::::R  D:::::D    D:::::D       G:::::G       GGGGGG           A:::::::::A           N::::::::::N    N::::::N G:::::G       GGGGGG       L:::::L        V:::::V           V:::::V   I::::I    I::::I      //
//      B::::B     B:::::B  I::::I    R::::R     R:::::R  D:::::D     D:::::D     G:::::G                        A:::::A:::::A          N:::::::::::N   N::::::NG:::::G                     L:::::L         V:::::V         V:::::V    I::::I    I::::I      //
//      B::::BBBBBB:::::B   I::::I    R::::RRRRRR:::::R   D:::::D     D:::::D     G:::::G                       A:::::A A:::::A         N:::::::N::::N  N::::::NG:::::G                     L:::::L          V:::::V       V:::::V     I::::I    I::::I      //
//      B:::::::::::::BB    I::::I    R:::::::::::::RR    D:::::D     D:::::D     G:::::G    GGGGGGGGGG        A:::::A   A:::::A        N::::::N N::::N N::::::NG:::::G    GGGGGGGGGG       L:::::L           V:::::V     V:::::V      I::::I    I::::I      //
//      B::::BBBBBB:::::B   I::::I    R::::RRRRRR:::::R   D:::::D     D:::::D     G:::::G    G::::::::G       A:::::A     A:::::A       N::::::N  N::::N:::::::NG:::::G    G::::::::G       L:::::L            V:::::V   V:::::V       I::::I    I::::I      //
//      B::::B     B:::::B  I::::I    R::::R     R:::::R  D:::::D     D:::::D     G:::::G    GGGGG::::G      A:::::AAAAAAAAA:::::A      N::::::N   N:::::::::::NG:::::G    GGGGG::::G       L:::::L             V:::::V V:::::V        I::::I    I::::I      //
//      B::::B     B:::::B  I::::I    R::::R     R:::::R  D:::::D     D:::::D     G:::::G        G::::G     A:::::::::::::::::::::A     N::::::N    N::::::::::NG:::::G        G::::G       L:::::L              V:::::V:::::V         I::::I    I::::I      //
//      B::::B     B:::::B  I::::I    R::::R     R:::::R  D:::::D    D:::::D       G:::::G       G::::G    A:::::AAAAAAAAAAAAA:::::A    N::::::N     N:::::::::N G:::::G       G::::G       L:::::L         LLLLLLV:::::::::V          I::::I    I::::I      //
//    BB:::::BBBBBB::::::BII::::::IIRR:::::R     R:::::RDDD:::::DDDDD:::::D         G:::::GGGGGGGG::::G   A:::::A             A:::::A   N::::::N      N::::::::N  G:::::GGGGGGGG::::G     LL:::::::LLLLLLLLL:::::L V:::::::V         II::::::IIII::::::II    //
//    B:::::::::::::::::B I::::::::IR::::::R     R:::::RD:::::::::::::::DD           GG:::::::::::::::G  A:::::A               A:::::A  N::::::N       N:::::::N   GG:::::::::::::::G     L::::::::::::::::::::::L  V:::::V          I::::::::II::::::::I    //
//    B::::::::::::::::B  I::::::::IR::::::R     R:::::RD::::::::::::DDD               GGG::::::GGG:::G A:::::A                 A:::::A N::::::N        N::::::N     GGG::::::GGG:::G     L::::::::::::::::::::::L   V:::V           I::::::::II::::::::I    //
//    BBBBBBBBBBBBBBBBB   IIIIIIIIIIRRRRRRRR     RRRRRRRDDDDDDDDDDDDD                     GGGGGG   GGGGAAAAAAA                   AAAAAAANNNNNNNN         NNNNNNN        GGGGGG   GGGG     LLLLLLLLLLLLLLLLLLLLLLLL    VVV            IIIIIIIIIIIIIIIIIIII    //
//                                                                                                                                                                                                                                                           //
//                                                                                                                                                                                                                                                           //
//                                                                                                                                                                                                                                                           //
//                                                                                                                                                                                                                                                           //
//                                                                                                                                                                                                                                                           //
//                                                                                                                                                                                                                                                           //
//                                                                                                                                                                                                                                                           //
//                                                                                                                                                                                                                                                           //
//                                                                                                                                                                                                                                                           //
//                                                                                                                                                                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract KCLVII is ERC1155Creator {
    constructor() ERC1155Creator("Bird Gang 2023", "KCLVII") {}
}