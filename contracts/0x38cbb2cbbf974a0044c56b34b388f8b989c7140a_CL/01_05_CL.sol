// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Cexa Logos
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                               //
//                                                                                                                                                                                                               //
//                                                                                                                                                                                                               //
//                                                                                                                                                                                                               //
//                                                                                                                                                                                                               //
//            CCCCCCCCCCCCCEEEEEEEEEEEEEEEEEEEEEEXXXXXXX       XXXXXXX               AAA               LLLLLLLLLLL                  OOOOOOOOO             GGGGGGGGGGGGG     OOOOOOOOO        SSSSSSSSSSSSSSS     //
//         CCC::::::::::::CE::::::::::::::::::::EX:::::X       X:::::X              A:::A              L:::::::::L                OO:::::::::OO        GGG::::::::::::G   OO:::::::::OO    SS:::::::::::::::S    //
//       CC:::::::::::::::CE::::::::::::::::::::EX:::::X       X:::::X             A:::::A             L:::::::::L              OO:::::::::::::OO    GG:::::::::::::::G OO:::::::::::::OO S:::::SSSSSS::::::S    //
//      C:::::CCCCCCCC::::CEE::::::EEEEEEEEE::::EX::::::X     X::::::X            A:::::::A            LL:::::::LL             O:::::::OOO:::::::O  G:::::GGGGGGGG::::GO:::::::OOO:::::::OS:::::S     SSSSSSS    //
//     C:::::C       CCCCCC  E:::::E       EEEEEEXXX:::::X   X:::::XXX           A:::::::::A             L:::::L               O::::::O   O::::::O G:::::G       GGGGGGO::::::O   O::::::OS:::::S                //
//    C:::::C                E:::::E                X:::::X X:::::X             A:::::A:::::A            L:::::L               O:::::O     O:::::OG:::::G              O:::::O     O:::::OS:::::S                //
//    C:::::C                E::::::EEEEEEEEEE       X:::::X:::::X             A:::::A A:::::A           L:::::L               O:::::O     O:::::OG:::::G              O:::::O     O:::::O S::::SSSS             //
//    C:::::C                E:::::::::::::::E        X:::::::::X             A:::::A   A:::::A          L:::::L               O:::::O     O:::::OG:::::G    GGGGGGGGGGO:::::O     O:::::O  SS::::::SSSSS        //
//    C:::::C                E:::::::::::::::E        X:::::::::X            A:::::A     A:::::A         L:::::L               O:::::O     O:::::OG:::::G    G::::::::GO:::::O     O:::::O    SSS::::::::SS      //
//    C:::::C                E::::::EEEEEEEEEE       X:::::X:::::X          A:::::AAAAAAAAA:::::A        L:::::L               O:::::O     O:::::OG:::::G    GGGGG::::GO:::::O     O:::::O       SSSSSS::::S     //
//    C:::::C                E:::::E                X:::::X X:::::X        A:::::::::::::::::::::A       L:::::L               O:::::O     O:::::OG:::::G        G::::GO:::::O     O:::::O            S:::::S    //
//     C:::::C       CCCCCC  E:::::E       EEEEEEXXX:::::X   X:::::XXX    A:::::AAAAAAAAAAAAA:::::A      L:::::L         LLLLLLO::::::O   O::::::O G:::::G       G::::GO::::::O   O::::::O            S:::::S    //
//      C:::::CCCCCCCC::::CEE::::::EEEEEEEE:::::EX::::::X     X::::::X   A:::::A             A:::::A   LL:::::::LLLLLLLLL:::::LO:::::::OOO:::::::O  G:::::GGGGGGGG::::GO:::::::OOO:::::::OSSSSSSS     S:::::S    //
//       CC:::::::::::::::CE::::::::::::::::::::EX:::::X       X:::::X  A:::::A               A:::::A  L::::::::::::::::::::::L OO:::::::::::::OO    GG:::::::::::::::G OO:::::::::::::OO S::::::SSSSSS:::::S    //
//         CCC::::::::::::CE::::::::::::::::::::EX:::::X       X:::::X A:::::A                 A:::::A L::::::::::::::::::::::L   OO:::::::::OO        GGG::::::GGG:::G   OO:::::::::OO   S:::::::::::::::SS     //
//            CCCCCCCCCCCCCEEEEEEEEEEEEEEEEEEEEEEXXXXXXX       XXXXXXXAAAAAAA                   AAAAAAALLLLLLLLLLLLLLLLLLLLLLLL     OOOOOOOOO             GGGGGG   GGGG     OOOOOOOOO      SSSSSSSSSSSSSSS       //
//                                                                                                                                                                                                               //
//                                                                                                                                                                                                               //
//                                                                                                                                                                                                               //
//                                                                                                                                                                                                               //
//                                                                                                                                                                                                               //
//                                                                                                                                                                                                               //
//                                                                                                                                                                                                               //
//                                                                                                                                                                                                               //
//                                                                                                                                                                                                               //
//                                                                                                                                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CL is ERC721Creator {
    constructor() ERC721Creator("Cexa Logos", "CL") {}
}