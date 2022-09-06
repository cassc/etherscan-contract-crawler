// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: aRRO
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                     //
//                                                                                     //
//                                                                                     //
//                                                                                     //
//                      RRRRRRRRRRRRRRRRR   RRRRRRRRRRRRRRRRR        OOOOOOOOO         //
//                      R::::::::::::::::R  R::::::::::::::::R     OO:::::::::OO       //
//                      R::::::RRRRRR:::::R R::::::RRRRRR:::::R  OO:::::::::::::OO     //
//                      RR:::::R     R:::::RRR:::::R     R:::::RO:::::::OOO:::::::O    //
//      aaaaaaaaaaaaa     R::::R     R:::::R  R::::R     R:::::RO::::::O   O::::::O    //
//      a::::::::::::a    R::::R     R:::::R  R::::R     R:::::RO:::::O     O:::::O    //
//      aaaaaaaaa:::::a   R::::RRRRRR:::::R   R::::RRRRRR:::::R O:::::O     O:::::O    //
//               a::::a   R:::::::::::::RR    R:::::::::::::RR  O:::::O     O:::::O    //
//        aaaaaaa:::::a   R::::RRRRRR:::::R   R::::RRRRRR:::::R O:::::O     O:::::O    //
//      aa::::::::::::a   R::::R     R:::::R  R::::R     R:::::RO:::::O     O:::::O    //
//     a::::aaaa::::::a   R::::R     R:::::R  R::::R     R:::::RO:::::O     O:::::O    //
//    a::::a    a:::::a   R::::R     R:::::R  R::::R     R:::::RO::::::O   O::::::O    //
//    a::::a    a:::::a RR:::::R     R:::::RRR:::::R     R:::::RO:::::::OOO:::::::O    //
//    a:::::aaaa::::::a R::::::R     R:::::RR::::::R     R:::::R OO:::::::::::::OO     //
//     a::::::::::aa:::aR::::::R     R:::::RR::::::R     R:::::R   OO:::::::::OO       //
//      aaaaaaaaaa  aaaaRRRRRRRR     RRRRRRRRRRRRRRR     RRRRRRR     OOOOOOOOO         //
//                                                                                     //
//                                                                                     //
//                                                                                     //
//                                                                                     //
//                                                                                     //
//                                                                                     //
//                                                                                     //
//                                                                                     //
//                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////


contract ARRO is ERC721Creator {
    constructor() ERC721Creator("aRRO", "ARRO") {}
}