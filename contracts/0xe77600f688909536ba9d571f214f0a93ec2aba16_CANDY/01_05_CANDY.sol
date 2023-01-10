// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BAD CANDY
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                         //
//                                                                                         //
//                                                                                         //
//    ░██████╗██╗░░██╗░█████╗░░██╗░░░░░░░██╗███╗░░██╗                                      //
//    ██╔════╝██║░░██║██╔══██╗░██║░░██╗░░██║████╗░██║                                      //
//    ╚█████╗░███████║███████║░╚██╗████╗██╔╝██╔██╗██║                                      //
//    ░╚═══██╗██╔══██║██╔══██║░░████╔═████║░██║╚████║                                      //
//    ██████╔╝██║░░██║██║░░██║░░╚██╔╝░╚██╔╝░██║░╚███║                                      //
//    ╚═════╝░╚═╝░░╚═╝╚═╝░░╚═╝░░░╚═╝░░░╚═╝░░╚═╝░░╚══╝                                      //
//                                                                                         //
//    ███╗░░░███╗░█████╗░██████╗░███████╗████████╗░█████╗░███╗░░██╗                        //
//    ████╗░████║██╔══██╗██╔══██╗██╔════╝╚══██╔══╝██╔══██╗████╗░██║                        //
//    ██╔████╔██║██║░░██║██████╔╝█████╗░░░░░██║░░░██║░░██║██╔██╗██║                        //
//    ██║╚██╔╝██║██║░░██║██╔══██╗██╔══╝░░░░░██║░░░██║░░██║██║╚████║                        //
//    ██║░╚═╝░██║╚█████╔╝██║░░██║███████╗░░░██║░░░╚█████╔╝██║░╚███║                        //
//    ╚═╝░░░░░╚═╝░╚════╝░╚═╝░░╚═╝╚══════╝░░░╚═╝░░░░╚════╝░╚═╝░░╚══╝                        //
//                                                                                         //
//                                                                                         //
//    ╔╗ ┌─┐┌┬┐  ╔═╗┌─┐┌┐┌┌┬┐┬ ┬                                                           //
//    ╠╩╗├─┤ ││  ║  ├─┤│││ ││└┬┘                                                           //
//    ╚═╝┴ ┴─┴┘  ╚═╝┴ ┴┘└┘─┴┘ ┴                                                            //
//                                                                                         //
//    License: Primary NFT holder is free to display privately and publicly in virtual     //
//    galleries, videos and other non-commercial displays produced by the                  //
//    holder of the NFT, as long as the creator is credited.                               //
//    This license provides no rights to create commercial merchandise,                    //
//    prints for sale, commercial distribution or derivative works.                        //
//    Copyright remains solely with the artist/creator, Shawn Moreton.                     //
//    All Rights Reserved.                                                                 //
//                                                                                         //
//                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////


contract CANDY is ERC721Creator {
    constructor() ERC721Creator("BAD CANDY", "CANDY") {}
}