// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Underworld.pixels
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//    ████████████████████████████████████████████████████████████████████████████████    //
//                                                                                        //
//    ████████████████████████████████████████████████████████████████████████████████    //
//                                                                                        //
//    ████████████████████████████████████████████████████████████████████████████████    //
//                                                                                        //
//    ████████████████████████████████████████████████████████████████████████████████    //
//                                                                                        //
//    ████████████████████████████████████████████████████████████████████████████████    //
//                                                                                        //
//    ████████████████████████████████████████████████████████████████████████████████    //
//                                                                                        //
//    ████████████████████████████████████████████████████████████████████████████████    //
//                                                                                        //
//    ████████████████████████████████████████████████████████████████████████████████    //
//                                                                                        //
//    ████████████████████████████████████████████████████████████████████████████████    //
//                                                                                        //
//    ████████████████████████████████████████████████████████████████████████████████    //
//                                                                                        //
//    ████████████████████████████████████████████████████████████████████████████████    //
//                                                                                        //
//    ████████████████████████████████████████████████████████████████████████████████    //
//                                                                                        //
//    ████████████████████████████████████████████████████████████████████████████████    //
//                                                                                        //
//    ████████████████████████████████████████████████████████████████████████████████    //
//                                                                                        //
//    ████████████████████▌╢▓███████████████████████████████████▓╢▓███████████████████    //
//                                                                                        //
//    █████████████████████╣▓▓█████████████████████████████████▓▓▓████████████████████    //
//                                                                                        //
//    █████████████▓▓███████▓▓██▓▓█████▌▓████▓▓███████████╣▓███▓▓▓█████▓▓▓████████████    //
//                                                                                        //
//    █████████████▓▓███████▓▓██▓▓██████▌▓╣██▓▓▓███████████▓▓██▓▓▓█████▓╢╫████████████    //
//                                                                                        //
//    █████████████▓▓███████▓▓██▓▓███████╣▓▓█▓▓▓████╢╣█████▓▓▓█▓▓▓█████▓██████████████    //
//                                                                                        //
//    ██████████████▓▓██████▓▓██▓▓███████▌▓╣█╣▓▓████▓▓▓████▓▓██▓▓▓█████▓▓▓████████████    //
//                                                                                        //
//    ██████████████████████████╣▓███████▓╫███████████████████████████████████████████    //
//                                                                                        //
//    ██████████████████████████████████▓█████████████████████████████████████████████    //
//                                                                                        //
//    ████████████████████████████████████████████████████████████████████████████████    //
//                                                                                        //
//    ████████████████████████████████████████████████████████████████████████████████    //
//                                                                                        //
//    ████████████████████████████████████████████████████████████████████████████████    //
//                                                                                        //
//    ████████████████████████████████████████████████████████████████████████████████    //
//                                                                                        //
//    ████████████████████████████████████████████████████████████████████████████████    //
//                                                                                        //
//    ████████████████████████████████████████████████████████████████████████████████    //
//                                                                                        //
//    ████████████████████████████████████████████████████████████████████████████████    //
//                                                                                        //
//    ████████████████████████████████████████████████████████████████████████████████    //
//                                                                                        //
//    ████████████████████████████████████████████████████████████████████████████████    //
//                                                                                        //
//    ████████████████████████████████████████████████████████████████████████████████    //
//                                                                                        //
//    ████████████████████████████████████████████████████████████████████████████████    //
//                                                                                        //
//    ████████████████████████████████████████████████████████████████████████████████    //
//                                                                                        //
//    ████████████████████████████████████████████████████████████████████████████████    //
//                                                                                        //
//    ████████████████████████████████████████████████████████████████████████████████    //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract UNWDP is ERC1155Creator {
    constructor() ERC1155Creator("Underworld.pixels", "UNWDP") {}
}