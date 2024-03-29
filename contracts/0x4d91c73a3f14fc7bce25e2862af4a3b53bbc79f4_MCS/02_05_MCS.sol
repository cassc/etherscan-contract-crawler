// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: David Marc
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                            //
//                                                                                            //
//                                                                                            //
//        ████████████████████████████████████████████████████████████████████████████████    //
//        ████████████████████████████████████████████████████████████████████████████████    //
//        ████████████████████████████████████████████████████████████████████████████████    //
//        █████████████████████████████████▀▒▒▒▒╣╢╢╢╣╢▒▒▒▀▀███████████████████████████████    //
//        █████████████████████████████▒▒╫╣╢╢╢╢╢╣╣╢╢▓▓▓▓▓▓▓▓▓╢████████████████████████████    //
//        ██████████████████████████▒╢╢╢╣╣╢╢▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒█████████████████████████    //
//        ████████████████████████▒╢▓╢▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓███████████████████████    //
//        ██████████████████████▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓╣█████████████████████    //
//        █████████████████████▌▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓███████████████████    //
//        █████████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██████████████████    //
//        █████████████████████▓╣▓▓▓▓▓██████▓▓▓▓▓▓▓▓▓█▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██████████████████    //
//        ██████████████████████▌▓▓▓████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█████████████████    //
//        ██████████████████████▓▓▓███████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██████████████████    //
//        █████████████████████▓▓▓▓████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██████████████████    //
//        ████████████████████▓▓█▓▓▓▓█████████████▓▓▓▓▓█▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██████████████████    //
//        ████████████████████▓▓███▓▓▓▓██████████▓▓▓▓███▓██▓▓▓▓▓▓▓▓▓▓▓╣███████████████████    //
//        ███████████████████▓▓▓███▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓████████▓▓▓▓▓▓▓▓▓▓█████████████████████    //
//        ████████████████████▓▓▓█▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██████▓▓▓▓▓▓▓▓▓███████████████████████    //
//        ██████████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█▓▓██████████████████████████    //
//        ██████████████████████▓▓▓▓▓▓▓▓▓█████████████████████████████████████████████████    //
//        ██████████████████████▓███▓▓▓▓██████████████████████████████████████████████████    //
//        ████████████████████████████████████████████████████████████████████████████████    //
//        ████████████████████████████████████████████████████████████████████████████████    //
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////


contract MCS is ERC721Creator {
    constructor() ERC721Creator("David Marc", "MCS") {}
}