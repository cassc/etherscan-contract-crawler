// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: #EDITIONVISION
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                        //
//                                                                                                        //
//    ██████╗██████╗ ██╗████████╗██╗ ██████╗ ███╗   ██╗    ██╗   ██╗██╗███████╗██╗ ██████╗ ███╗   ██╗     //
//    ██╔════╝██╔══██╗██║╚══██╔══╝██║██╔═══██╗████╗  ██║    ██║   ██║██║██╔════╝██║██╔═══██╗████╗  ██║    //
//    █████╗  ██║  ██║██║   ██║   ██║██║   ██║██╔██╗ ██║    ██║   ██║██║███████╗██║██║   ██║██╔██╗ ██║    //
//    ██╔══╝  ██║  ██║██║   ██║   ██║██║   ██║██║╚██╗██║    ╚██╗ ██╔╝██║╚════██║██║██║   ██║██║╚██╗██║    //
//    ███████╗██████╔╝██║   ██║   ██║╚██████╔╝██║ ╚████║     ╚████╔╝ ██║███████║██║╚██████╔╝██║ ╚████║    //
//    ╚══════╝╚═════╝ ╚═╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝      ╚═══╝  ╚═╝╚══════╝╚═╝ ╚═════╝ ╚═╝  ╚═══╝    //
//    GET PART OF EDITION VISION /// MANIFOLD ERC721 CONTRACT BY HANNESWINDRATH.ETH                       //
//                                                                                                        //
//                                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract EDITIONVISION is ERC721Creator {
    constructor() ERC721Creator("#EDITIONVISION", "EDITIONVISION") {}
}