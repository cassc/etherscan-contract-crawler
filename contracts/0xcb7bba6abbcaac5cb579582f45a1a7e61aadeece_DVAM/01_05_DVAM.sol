// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Derivatives by Angela Mantilla
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////
//                                                    //
//                                                    //
//       _____                                        //
//      (, /  |                  /)                   //
//        /---|  __     _    _  //   _                //
//     ) /    |_ / (_  (_/__(/_(/_  (_(_              //
//    (_/             .-/                             //
//                   (_/                              //
//       __     __)                                   //
//      (, /|  /|                 ,   /)   /)         //
//        / | / |    _  __  _/_      //   //   _      //
//     ) /  |/  |_  (_(_/ (_(__ _(_ (/_  (/_  (_(_    //
//    (_/   '                                         //
//                                                    //
//                                                    //
//                                                    //
//                                                    //
////////////////////////////////////////////////////////


contract DVAM is ERC721Creator {
    constructor() ERC721Creator("Derivatives by Angela Mantilla", "DVAM") {}
}