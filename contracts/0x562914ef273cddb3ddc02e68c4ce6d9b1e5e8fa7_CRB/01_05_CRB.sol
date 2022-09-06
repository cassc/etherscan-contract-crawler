// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Conserve Roty Broi
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////
//                                                                                 //
//                                                                                 //
//    ██████╗ ██████╗  ██████╗ ███████╗    ███╗   ██╗ ██████╗ ████████╗ █████╗     //
//    ██╔══██╗██╔══██╗██╔═══██╗██╔════╝    ████╗  ██║██╔═══██╗╚══██╔══╝██╔══██╗    //
//    ██████╔╝██████╔╝██║   ██║█████╗      ██╔██╗ ██║██║   ██║   ██║   ███████║    //
//    ██╔═══╝ ██╔══██╗██║   ██║██╔══╝      ██║╚██╗██║██║   ██║   ██║   ██╔══██║    //
//    ██║     ██║  ██║╚██████╔╝██║██╗      ██║ ╚████║╚██████╔╝   ██║   ██║  ██║    //
//    ╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚═╝╚═╝      ╚═╝  ╚═══╝ ╚═════╝    ╚═╝   ╚═╝  ╚═╝    //
//                                                                                 //
//    !Disclaimer!                                                                 //
//    This smart contract was created                                              //
//    for the purpose to deploy                                                    //
//    the CONSERVE ROTY BROI collection                                            //
//    on the blockchain.                                                           //
//                                                                                 //
//    This happened when ROTY BROI's ark                                           //
//    stranded in BALI island after                                                //
//    bear market glitch.                                                          //
//                                                                                 //
//    This collection is part of The                                               //
//    King's NFT, an artifact project                                              //
//    by @MyMyReceipt.                                                             //
//                                                                                 //
//    The complete story                                                           //
//    can be read here:                                                            //
//    github.com/the-aha-llf/the-kings-nft/wiki/Preface...                         //
//                                                                                 //
//    Prof. NOTA - @MyReceiptt - @MyReceipt                                        //
//                                                                                 //
//    ██████╗ ██████╗  ██████╗ ███████╗    ███╗   ██╗ ██████╗ ████████╗ █████╗     //
//    ██╔══██╗██╔══██╗██╔═══██╗██╔════╝    ████╗  ██║██╔═══██╗╚══██╔══╝██╔══██╗    //
//    ██████╔╝██████╔╝██║   ██║█████╗      ██╔██╗ ██║██║   ██║   ██║   ███████║    //
//    ██╔═══╝ ██╔══██╗██║   ██║██╔══╝      ██║╚██╗██║██║   ██║   ██║   ██╔══██║    //
//    ██║     ██║  ██║╚██████╔╝██║██╗      ██║ ╚████║╚██████╔╝   ██║   ██║  ██║    //
//    ╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚═╝╚═╝      ╚═╝  ╚═══╝ ╚═════╝    ╚═╝   ╚═╝  ╚═╝    //
//                                                                                 //
//                                                                                 //
//                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////


contract CRB is ERC721Creator {
    constructor() ERC721Creator("Conserve Roty Broi", "CRB") {}
}