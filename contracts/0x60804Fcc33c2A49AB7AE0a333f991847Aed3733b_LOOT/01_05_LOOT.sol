// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LOOTBAG
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                               //
//                                                                                                                                                               //
//                                                                                                                                                               //
//                                                                                                                                                               //
//    LLLLLLLLLLL                  OOOOOOOOO          OOOOOOOOO     TTTTTTTTTTTTTTTTTTTTTTTBBBBBBBBBBBBBBBBB               AAA                  GGGGGGGGGGGGG    //
//    L:::::::::L                OO:::::::::OO      OO:::::::::OO   T:::::::::::::::::::::TB::::::::::::::::B             A:::A              GGG::::::::::::G    //
//    L:::::::::L              OO:::::::::::::OO  OO:::::::::::::OO T:::::::::::::::::::::TB::::::BBBBBB:::::B           A:::::A           GG:::::::::::::::G    //
//    LL:::::::LL             O:::::::OOO:::::::OO:::::::OOO:::::::OT:::::TT:::::::TT:::::TBB:::::B     B:::::B         A:::::::A         G:::::GGGGGGGG::::G    //
//      L:::::L               O::::::O   O::::::OO::::::O   O::::::OTTTTTT  T:::::T  TTTTTT  B::::B     B:::::B        A:::::::::A       G:::::G       GGGGGG    //
//      L:::::L               O:::::O     O:::::OO:::::O     O:::::O        T:::::T          B::::B     B:::::B       A:::::A:::::A     G:::::G                  //
//      L:::::L               O:::::O     O:::::OO:::::O     O:::::O        T:::::T          B::::BBBBBB:::::B       A:::::A A:::::A    G:::::G                  //
//      L:::::L               O:::::O     O:::::OO:::::O     O:::::O        T:::::T          B:::::::::::::BB       A:::::A   A:::::A   G:::::G    GGGGGGGGGG    //
//      L:::::L               O:::::O     O:::::OO:::::O     O:::::O        T:::::T          B::::BBBBBB:::::B     A:::::A     A:::::A  G:::::G    G::::::::G    //
//      L:::::L               O:::::O     O:::::OO:::::O     O:::::O        T:::::T          B::::B     B:::::B   A:::::AAAAAAAAA:::::A G:::::G    GGGGG::::G    //
//      L:::::L               O:::::O     O:::::OO:::::O     O:::::O        T:::::T          B::::B     B:::::B  A:::::::::::::::::::::AG:::::G        G::::G    //
//      L:::::L         LLLLLLO::::::O   O::::::OO::::::O   O::::::O        T:::::T          B::::B     B:::::B A:::::AAAAAAAAAAAAA:::::AG:::::G       G::::G    //
//    LL:::::::LLLLLLLLL:::::LO:::::::OOO:::::::OO:::::::OOO:::::::O      TT:::::::TT      BB:::::BBBBBB::::::BA:::::A             A:::::AG:::::GGGGGGGG::::G    //
//    L::::::::::::::::::::::L OO:::::::::::::OO  OO:::::::::::::OO       T:::::::::T      B:::::::::::::::::BA:::::A               A:::::AGG:::::::::::::::G    //
//    L::::::::::::::::::::::L   OO:::::::::OO      OO:::::::::OO         T:::::::::T      B::::::::::::::::BA:::::A                 A:::::A GGG::::::GGG:::G    //
//    LLLLLLLLLLLLLLLLLLLLLLLL     OOOOOOOOO          OOOOOOOOO           TTTTTTTTTTT      BBBBBBBBBBBBBBBBBAAAAAAA                   AAAAAAA   GGGGGG   GGGG    //
//                                                                                                                                                               //
//                                                                                                                                                               //
//                                                                                                                                                               //
//                                                                                                                                                               //
//                                                                                                                                                               //
//                                                                                                                                                               //
//                                                                                                                                                               //
//                                                                                                                                                               //
//                                                                                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract LOOT is ERC721Creator {
    constructor() ERC721Creator("LOOTBAG", "LOOT") {}
}