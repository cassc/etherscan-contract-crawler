// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Follow Shadows
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////
//                                                                                 //
//                                                                                 //
//                                                                                 //
//                                                                                 //
//                                    ,╓╔φφφ▒░░░░░░░░░░φφ≥≡,                       //
//                               ╓φ▒░░░░░░░░░░░████▌░░░░░░░░░░░φ≥,                 //
//                           ╓φ▒░░░░░░░░░░░░░░▀█████│░░░░░░░░░░░░░░░≤,             //
//                        «φ░░░░░░░░░░░░░░░░░░░╟███▒░░░░░░░░░░░░││││''│░           //
//                     ,φ░░░░░░░░░░░░░░░░░░Q▄▄▓██████▓▄▄░░░░│││││'''''   ░≥        //
//                   ,φ░░░░░░░░░░░░░░░░░░░▓█████████████▌░││││││''''        ░      //
//                 ,φ░░░░░░░░░░░░░░░░░░░░░███████████████░││'.'''  '          .    //
//                φ░░░░░░░░░░░░░░░░░░░░░░░███████████████▒''''  '                  //
//              ,φ░░░░░░░░░░░░░░░░░░░░░░░░███████████████▌' ''                     //
//             ,░░░░░░░░░░░░░░░░░░░░░░░░░j█████████████└╙'                         //
//            ,░░░░░░░░░░░░░░░░░░░░░│││░│╟█████████████⌐                           //
//            ░░░░░░░░░░░░░░░░░│░░││││││.██████████████▌                           //
//           φ░░░░░░░░░░░░░░││││││'''''']███████████████                           //
//           ░│░░░░░││││││││'''''''''    ╟█▌'██████████                            //
//          [││││││'│''''''''''''  ''     '  ╟█████████                            //
//          │''''''''''''   '                ╙███▌╙████                            //
//          ' ''  ' ''                        ███▌ ╙███                            //
//                                            ███⌐  ███                            //
//                                            ╟██▒ ]███                            //
//          .                                 ⌠██▒ ▐██⌐                            //
//                                             ██▌.███                             //
//           '                                 ▐██▓██                              //
//                                             ██████                              //
//                                             ███ ███                             //
//                                             ╟█▌ └▀▀                             //
//                                             ██¬                                 //
//                                            ███   █▄                             //
//                                           ]██¬  ██▌                             //
//                                           ██▌  ╫██▌                             //
//                                          ███⌐  ███▌                             //
//                                         ▐███  ▐███                              //
//                                         ███▌  ███▌                              //
//                                        ╫███⌐ ▐███                               //
//                                        ████  ███▌                               //
//                                                                                 //
//                                                                                 //
//    ---                                                                          //
//    ^[ [^ascii ^art ^followshadows](gokhangogo) ^]                               //
//                                                                                 //
//                                                                                 //
//                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////


contract shadw is ERC721Creator {
    constructor() ERC721Creator("Follow Shadows", "shadw") {}
}