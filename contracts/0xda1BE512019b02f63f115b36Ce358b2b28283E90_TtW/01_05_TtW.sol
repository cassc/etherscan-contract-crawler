// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: SNI's Tracing the Wild
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////
//                                                                             //
//                                                                             //
//    "Tracing the Wild" is a new dynamic data-driven art project led by       //
//    Nairobi-based artist Chuma Anagbado alongside creativity hub Nairobi     //
//    Design in collaboration with data architect Daria Smakhtina and          //
//    the Sovereign Nature Initiative's Director of Creative Engagement        //
//    Seth Bockley. This initiative visualizes predator data from              //
//    Kenya Wildlife Trust (KWT) as a series of digital and physical           //
//    data-based 'portraits' along with interactive artwork created with       //
//    tech developers, designers, and story gatherers.                         //
//                                                                             //
//    This project harnesses data from lions' patterns of territorial          //
//    movement and conflict with humans in order to represent the predator     //
//    ecosystem in Kenya's Maasai Mara region as a dynamic human-nonhuman      //
//    collaborative artwork, providing a vivid and emotionally affective       //
//    experience of scientific knowledge and real-time health of nature.       //
//                                                                             //
//                                                                             //
/////////////////////////////////////////////////////////////////////////////////


contract TtW is ERC1155Creator {
    constructor() ERC1155Creator("SNI's Tracing the Wild", "TtW") {}
}