// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Kids of Love
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                    //
//                                                                                                    //
//    LLLLLLLLLLL                  OOOOOOOOO     VVVVVVVV           VVVVVVVVEEEEEEEEEEEEEEEEEEEEEE    //
//    L:::::::::L                OO:::::::::OO   V::::::V           V::::::VE::::::::::::::::::::E    //
//    L:::::::::L              OO:::::::::::::OO V::::::V           V::::::VE::::::::::::::::::::E    //
//    LL:::::::LL             O:::::::OOO:::::::OV::::::V           V::::::VEE::::::EEEEEEEEE::::E    //
//      L:::::L               O::::::O   O::::::O V:::::V           V:::::V   E:::::E       EEEEEE    //
//      L:::::L               O:::::O     O:::::O  V:::::V         V:::::V    E:::::E                 //
//      L:::::L               O:::::O     O:::::O   V:::::V       V:::::V     E::::::EEEEEEEEEE       //
//      L:::::L               O:::::O     O:::::O    V:::::V     V:::::V      E:::::::::::::::E       //
//      L:::::L               O:::::O     O:::::O     V:::::V   V:::::V       E:::::::::::::::E       //
//      L:::::L               O:::::O     O:::::O      V:::::V V:::::V        E::::::EEEEEEEEEE       //
//      L:::::L               O:::::O     O:::::O       V:::::V:::::V         E:::::E                 //
//      L:::::L         LLLLLLO::::::O   O::::::O        V:::::::::V          E:::::E       EEEEEE    //
//    LL:::::::LLLLLLLLL:::::LO:::::::OOO:::::::O         V:::::::V         EE::::::EEEEEEEE:::::E    //
//    L::::::::::::::::::::::L OO:::::::::::::OO           V:::::V          E::::::::::::::::::::E    //
//    L::::::::::::::::::::::L   OO:::::::::OO              V:::V           E::::::::::::::::::::E    //
//    LLLLLLLLLLLLLLLLLLLLLLLL     OOOOOOOOO                 VVV            EEEEEEEEEEEEEEEEEEEEEE    //
//                                                                                                    //
//                                                                                                    //
//                                                                                                    //
//                                                                                                    //
//                                                                                                    //
//                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////


contract LOVE is ERC721Creator {
    constructor() ERC721Creator("The Kids of Love", "LOVE") {}
}