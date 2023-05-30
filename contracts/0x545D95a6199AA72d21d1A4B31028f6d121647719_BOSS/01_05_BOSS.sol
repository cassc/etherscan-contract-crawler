// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BOSS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                             //
//                                                                                                             //
//                                                                                                             //
//                                                                                                             //
//                                                                                                             //
//                                                                                                             //
//                                                                                                             //
//                                                                                                             //
//    BBBBBBBBBBBBBBBBB        OOOOOOOOO        SSSSSSSSSSSSSSS    SSSSSSSSSSSSSSS                             //
//    B::::::::::::::::B     OO:::::::::OO    SS:::::::::::::::S SS:::::::::::::::S                            //
//    B::::::BBBBBB:::::B  OO:::::::::::::OO S:::::SSSSSS::::::SS:::::SSSSSS::::::S                            //
//    BB:::::B     B:::::BO:::::::OOO:::::::OS:::::S     SSSSSSSS:::::S     SSSSSSS                            //
//      B::::B     B:::::BO::::::O   O::::::OS:::::S            S:::::S                                        //
//      B::::B     B:::::BO:::::O     O:::::OS:::::S            S:::::S                                        //
//      B::::BBBBBB:::::B O:::::O     O:::::O S::::SSSS          S::::SSSS                                     //
//      B:::::::::::::BB  O:::::O     O:::::O  SS::::::SSSSS      SS::::::SSSSS                                //
//      B::::BBBBBB:::::B O:::::O     O:::::O    SSS::::::::SS      SSS::::::::SS                              //
//      B::::B     B:::::BO:::::O     O:::::O       SSSSSS::::S        SSSSSS::::S                             //
//      B::::B     B:::::BO:::::O     O:::::O            S:::::S            S:::::S                            //
//      B::::B     B:::::BO::::::O   O::::::O            S:::::S            S:::::S                            //
//    BB:::::BBBBBB::::::BO:::::::OOO:::::::OSSSSSSS     S:::::SSSSSSSS     S:::::S                            //
//    B:::::::::::::::::B  OO:::::::::::::OO S::::::SSSSSS:::::SS::::::SSSSSS:::::S                            //
//    B::::::::::::::::B     OO:::::::::OO   S:::::::::::::::SS S:::::::::::::::SS                             //
//    BBBBBBBBBBBBBBBBB        OOOOOOOOO      SSSSSSSSSSSSSSS    SSSSSSSSSSSSSSS                               //
//                                                                                                             //
//     Thank you, boss...                                                                                      //
//                                                                                                             //
//                                                                                                             //
//                                                                                                             //
//                                                                                                             //
//                                                                                                             //
//                                                                                                             //
//                                                                                                             //
//                                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BOSS is ERC1155Creator {
    constructor() ERC1155Creator("BOSS", "BOSS") {}
}