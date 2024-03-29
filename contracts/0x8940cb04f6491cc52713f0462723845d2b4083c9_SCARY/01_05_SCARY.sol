// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GoldiesNFTart
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                            //
//                                                                                            //
//                                                                                            //
//        ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//        ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//        ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//        ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//        ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//        ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░╫µ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//        ░░░░░░░░░░░░░░░░░░░░░░░░░░░░Ñ▒µ░░║▒░▄░░░╥░░░░░░░░░░░░░▄▓░░░░░░░░░░░░░░░░░░░░░░░░    //
//        ░░░░░░░░░░░░░░░░░░░░░░░░░╚▒µ░░▓█▓█▓███▓▀▀▀▓▓█▓▄▒░░░▄█▀░░▄██░░░░░░░░░░░░░░░░░░░░░    //
//        ░░░░░░░░░░░░░░░░░░░░░░░▒▒▄▒▀█▄▄███▀█▒@▒▒▒▒▒▒▒▒▒▒▀███░╖▓██░░░░░░░░░░░░░░░░░░░░░░░    //
//        ░░░░░░░░░░░░░░░░░░░░░░░#▀╫▓▓▀▒▒▒█▌▒▒▒▒▒▒▒▒▒▒▒▒▒▒▀█▒█████▄██▀░░░░░░░░░░░░░░░░░░░░    //
//        ░░░░░░░░░░░░░░░░░░░░░▒░╓@█▒▀▒▒▒▒██╗█▓▓▓▒▒▓█▒▒▒▒▒▒▒▒█▒███▀░░░░░░░░░░░░░░░░░░░░░░░    //
//        ░░░░░░░░░░░░░░░░░░░░▒░▓▒░▒▒▒▒▒░▒▒█▓▒▒▒▒▒██▒▒▒▒▒▒▒▒▒▒▒█▀▓▒░░░░░░░░░░░░░░░░░░░░░░░    //
//        ░░░░░░░░░░░░░░░░░░░╣▒▀▒░░▒▒▒▒▒▒▒░█▓▒▀▒▓██▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒█▌░░░░░░░░░░░░░░░░░░░░░░    //
//        ░░░░░░░░░░░░░░░░░░▒▓▀╬▒▒░▒▒▒▒▒▒▒░███▀▓██▒▒▒▒▒▒▓▓▓▒▒▒▒▒▒▒▒█▒░░░░░░░░░░░░░░░░░░░░░    //
//        ░░░░░░░░░░░░░░░░░░▓░▒░░▄▒▄▓▒▒▒▒░▒█▒▒║██▓███▀╣█▒█▒▀▀█▒▒▒▒▒██░░░░░░░░░░░░░░░░░░░░░    //
//        ░░░░░░░░░░░░░░░░░▓▒╢▒▒▀██████▀▓▀j▓@▒▒▀▀▒╙▒▓█▓▓▓▓▓▓▀▒▒▒▒▒▒██░░░░░░░░░░░░░░░░░░░░░    //
//        ░░░░░░░░░░░░░░░░╫▌▐▒▒░▒▒▓▓▓▓▓░▒▒▓▓▓▒▒▒█▄▓▓▓▓▓▓█████▓░▒▒▒▒╣█░░░░░░░░░░░░░░░░░░░░░    //
//        ░░░░░░░░░░░░░░░░█▒▒░▒▄▓▓▓▓███▌░▓███▓▒▒▓████▀░░░▄██▓█▒▒▒▒▒▒█▒░░░░░░░░░░░░░░░░░░░░    //
//        ░░░░░░░░░░░░░░░╫█▀░▒▐█▓█▀▀███░███@██@▒███▓▒█▓█████▓▒▒▒▒▒▒╫█▒░░░░░░░░░░░░░░░░░░░░    //
//        ░░░░░░░░░░░░░░░▓█░░▒██@█▓███▒████▓▓██▒▒▀███▓█▓██▀▀▒▒▒▒▒▒▒██▌░░░░░░░░░░░░░░░░░░░░    //
//        ░░░░░░░░░░░░░░▐█░▒▒░██████▀▒▓█▌██▓████▒▒▒▒░▒▒▒▒▄▓▓▓@▓▒▒▒▒█▌░░░░░░░░░░░░░░░░░░░░░    //
//        ░░░░░░░░░░░░░╓██▒▒▒▒▒░░▒▓M▒▒▒▀███▓▀▀▀▒▒▒▒▒▒▒▄▓██████▒▒▒▒▒█░░░░░░░░░░░░░░░░░░░░░░    //
//        ░░░░░░░░░░░░░▓▓▓▒▒░░▒░▒@█╬▒▒▓▓▒▒▒▒░▒░░▒▒▄▓▓████▒▒▒█▀▒▒▒▒█▌░░░░░░░░░░░░░░░░░░░░░░    //
//        ░░░░░░░░░░░░▐▓█▒▒░▒▒░░░▓██▒▓█▓▓███████████████▓▒▒║▌╫▒▒▒██░░░░░░░░░░░░░░░░░░░░░░░    //
//        ░░░░░░░░░░░░░▒█▒░▒▒▒▒░▒▒▄███████████████████████▓▒▒▒▒▒█▀░░░░░░░░░░░░░░░░░░░░░░░░    //
//        ░░░░░░░░░░░░░▒▓▒▒▒░▒▒▒██████████▓███████████████▓▒▒▒▓█▀░░░░░░░░░░░░░░░░░░░░░░░░░    //
//        ░░░░░░░░░░░░░░▓█▒▒░▒▒██████████████████████████▒▒▓▒█▀░░░░░░░░░░░░░░░░░░░░░░░░░░░    //
//        ░░░░░░░░░░░░░░▐█▓▒▒▒▒████████████████████████▒▓▓▒█▀░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒    //
//        ░░░░░░░░░░░░░░░▒▓▓▒▒▒█████████████████████▓██▒▀▀░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒    //
//        ░░░░░░░░░░░░░░░░▒▓█▓▓▒▀████▓████▀███▓▓▀█▀▀░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒    //
//        ░░░░░░░░░░░░░░░░░░░▒▒▒██▓▓▓▓███▀▀▀▀░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒    //
//        ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒    //
//        ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒    //
//        ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒░░▒▒▒▒▒▒    //
//        ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒    //
//        ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒    //
//        ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒    //
//        ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒    //
//        ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒    //
//        ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒    //
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////


contract SCARY is ERC1155Creator {
    constructor() ERC1155Creator("GoldiesNFTart", "SCARY") {}
}