// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: OFF-1566
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                                                                            //
//                                                                            //
//                                                                            //
//         OOOOOOOOO     FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF !!!     //
//       OO:::::::::OO   F::::::::::::::::::::FF::::::::::::::::::::F!!:!!    //
//     OO:::::::::::::OO F::::::::::::::::::::FF::::::::::::::::::::F!:::!    //
//    O:::::::OOO:::::::OFF::::::FFFFFFFFF::::FFF::::::FFFFFFFFF::::F!:::!    //
//    O::::::O   O::::::O  F:::::F       FFFFFF  F:::::F       FFFFFF!:::!    //
//    O:::::O     O:::::O  F:::::F               F:::::F             !:::!    //
//    O:::::O     O:::::O  F::::::FFFFFFFFFF     F::::::FFFFFFFFFF   !:::!    //
//    O:::::O     O:::::O  F:::::::::::::::F     F:::::::::::::::F   !:::!    //
//    O:::::O     O:::::O  F:::::::::::::::F     F:::::::::::::::F   !:::!    //
//    O:::::O     O:::::O  F::::::FFFFFFFFFF     F::::::FFFFFFFFFF   !:::!    //
//    O:::::O     O:::::O  F:::::F               F:::::F             !!:!!    //
//    O::::::O   O::::::O  F:::::F               F:::::F              !!!     //
//    O:::::::OOO:::::::OFF:::::::FF           FF:::::::FF                    //
//     OO:::::::::::::OO F::::::::FF           F::::::::FF            !!!     //
//       OO:::::::::OO   F::::::::FF           F::::::::FF           !!:!!    //
//         OOOOOOOOO     FFFFFFFFFFF           FFFFFFFFFFF            !!!     //
//                                                                            //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////


contract OFF is ERC1155Creator {
    constructor() ERC1155Creator("OFF-1566", "OFF") {}
}