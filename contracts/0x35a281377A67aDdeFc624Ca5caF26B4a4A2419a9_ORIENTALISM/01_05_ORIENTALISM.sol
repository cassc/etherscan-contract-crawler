// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Eastern Promises
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//    ////////////////////////////////////////////////////////////////////////////////    //
//    ////////////////////////////////////////////////////////////////////////////////    //
//    The Eastern Promises:                                                               //
//    ////////////////////////////////////////////////////////////////////////////////    //
//    ////////////////////////////////////////////////////////////////////////////////    //
//                                                                                        //
//    Preserving Orientalist Painting Through Data Science invites us to consider         //
//    the role of technology in art and the ways in which it can be utilised              //
//    to engage in new forms of artistic expression. Art as a meta-discipline             //
//    is “an umbrella encompassing history, philosophy, nature and science.”              //
//    The AI-powered paintings presented by Mammadov offer a fresh and innovative         //
//    take on a timeless artistic tradition, provide a glimpse into the future of         //
//    art-making in the digital age, and raise crucial questions about polarisation,      //
//    redefining our rapidly developing world as well as exploring and preserving         //
//    the social and cultural heritage of humanity, with its own intricacies,             //
//    in a way that has yet to be decoded by future generations.                          //
//                                                                                        //
//    ////////////////////////////////////////////////////////////////////////////////    //
//    ARTIST: ORKHAN MAMMADOV                                                             //
//    DATE OF CREATION: 2023                                                              //
//    ////////////////////////////////////////////////////////////////////////////////    //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract ORIENTALISM is ERC721Creator {
    constructor() ERC721Creator("Eastern Promises", "ORIENTALISM") {}
}