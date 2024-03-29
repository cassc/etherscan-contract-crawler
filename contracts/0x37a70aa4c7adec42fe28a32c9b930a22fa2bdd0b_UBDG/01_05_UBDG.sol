// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Utility By Design
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                            //
//                                                                                            //
//                                                                                            //
//        ████████████████████████████████╬░,█████████████████████████████████████████████    //
//        █████████████████████████████████╣██████████  └╫▌ .██╦███████████▀▀╙  ,█████████    //
//        ███████████████████████████████╬┘,╠████████ ,▓█▒▓▓╬▓▓███████████▓███████████████    //
//        █████████████████████████████████▌╬┘████▓██▌╬╬▓▓▓███████████████████████████████    //
//        █████████████████████████████████▒..█████▓╣╣╣╣╣╣████████████████████████████████    //
//        ████████████████████╣████████████µ ╔████╣╣╣╣╣╣╣╫████████╬███████████████████████    //
//        ███████████████████╣╣╬██████████████████▓╣╣╣╣╣╣╣█╣▓█╣▓██████████████████████████    //
//        ██████████████████▓╣╣╣╣▓█████████████████▓╣╣╣╣╣██╣███╣╣╣████████████████████████    //
//        ██████████████████▓╣╣╣╣╣╣╣▓███████████████████▓▓███╣████████████████████████████    //
//        ███████████████▓███╣╣╣╣╣╣╣╣╣╣╣╣╣██████████████████████████╙█████████████████████    //
//        ████████████████╣▓▓╣╣╣╣╣╣╣╣╣╣╣╣╣██████████████████████████┌█████████████████████    //
//        ██████████████╬╬╣╣╣╣╣╢███▓╬▓╣╣╣╣██████████████████████████∩█████████████████████    //
//        ████████████▓███╣╣╣╣▓█▓╣▓███╣╣╣╣▓████████████▀╨▀██████████░█████████████████████    //
//        ███████████╬██▓╣╣╣╣▓█╣╣███╬╣╣╣╣╣▓███████████'....'███████████▓██▌█▓▓████████████    //
//        ███████████╣██╣╣╣╣╣██╣╣██╣╣╣╣╣╣╣╣██████████ ......"█████████╫████▌▌▓████████████    //
//        ███████████╣██╣╣╣╣╣██╣╣█▓╣╣╣╣╣╣╣╣╫█████████▒;......█████████╫╬███▓▓█▓███████████    //
//        ███████████╣▓█╣╣╣╣╣██╣▓█╣╣╣╣╣╣╣╣╣╣██████▓▓█▓▓▒┐...▐███████████▓▓╬╬╬▄████████████    //
//        ████████████╣█▓╣╣╣╣██╬╣█▓╣╣╣╣╣╣╣╣╣╬█████████╣╣╣▌.▄██████████████████████▓███████    //
//        █████████████╣█▓╣╣╣▓██╣╫█╣╣╣╣╣╣╣▓██▓▓╬╣╣╣╣╣╣▓████████████████████▌██████████████    //
//        ███████████████╣╣╣╣╣▓██╬╣╣╣╣╣╣╣╣██▓▓╬╣▓▓█████████████████▀▓█████████████╙▐██████    //
//                                                                                            //
//    ---                                                                                     //
//    asciiart.club                                                                           //
//                                                                                            //
//                                                                                            //
//                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////


contract UBDG is ERC721Creator {
    constructor() ERC721Creator("Utility By Design", "UBDG") {}
}