// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Nomad Bazaar
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//    ███╗░░██╗░█████╗░███╗░░░███╗░█████╗░██████╗░  ██████╗░░█████╗░███████╗░█████╗░░█████╗░██████╗░          //
//    ████╗░██║██╔══██╗████╗░████║██╔══██╗██╔══██╗  ██╔══██╗██╔══██╗╚════██║██╔══██╗██╔══██╗██╔══██╗          //
//    ██╔██╗██║██║░░██║██╔████╔██║███████║██║░░██║  ██████╦╝███████║░░███╔═╝███████║███████║██████╔╝          //
//    ██║╚████║██║░░██║██║╚██╔╝██║██╔══██║██║░░██║  ██╔══██╗██╔══██║██╔══╝░░██╔══██║██╔══██║██╔══██╗          //
//    ██║░╚███║╚█████╔╝██║░╚═╝░██║██║░░██║██████╔╝  ██████╦╝██║░░██║███████╗██║░░██║██║░░██║██║░░██║          //
//    ╚═╝░░╚══╝░╚════╝░╚═╝░░░░░╚═╝╚═╝░░╚═╝╚═════╝░  ╚═════╝░╚═╝░░╚═╝╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝          //
//                                                                                                            //
//    While Caleb and Madelyn have set out to complete long-distance travels across the globe,                //
//    they continue seeking inspiration between what’s finished and what’s to come. During those moments,     //
//    they’re given a chance to expand their creativity and evolve with temporary environments.               //
//                                                                                                            //
//    Capturing their fleeting interactions with varying landscapes, Caleb and Madelyn bring these            //
//    worthwhile pieces to the Nomad Bazaar.                                                                  //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract NOMAD is ERC721Creator {
    constructor() ERC721Creator("Nomad Bazaar", "NOMAD") {}
}