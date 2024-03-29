// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: chippi comics
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                                                                                            //
//                                                                                            //
//        ─╖_                                                                          .═¬    //
//             '¬╖_                                                                ▄^`        //
//                 "v                                                           ,M            //
//                    ¥         ╓▓███  ██▌  ██▓ ▄▓▓  ▓████▓, █████▓  ███▓      ▀              //
//                     ╙_     ▄█████▀  ███  ██▌ ███▌ ███  ██ ██▌  █▌ ████     ▌   _           //
//            ▓▄    ▓   `╕   ▐██▀      ███▄▄██▌ ╫██  ███▄▓██ ███╓▓█  ╫███    █   ▐█    █▌     //
//            ╙█    ▀L   ╙   ███       ╫███████ ▐██  ▓███▀"  ████▀   ▐██▌   ╫          "      //
//                        ▌  ╫██,      ╟██` ███  ██  ╫██     ██▌      ██▌   █                 //
//                        █   ▓███▓▓█▌ ▐██  ▓██  ██  ╫██     ██▌      ██▌  ▐▌ "▀▀▀▀▀▓▓ææ≤≤    //
//           A""""▀▀▀▀▀   ▓    '▀████"  ▀▀       '`   "      "╙            ▐H,─ⁿ"`            //
//           ▀═╖▄╓,,      ╫                                              ,∞"                  //
//              _,,▄╖╖▄,_ ▐               _,,▄╖╖,,_                    ┌Γ                     //
//         ╓⌐^"           `ⁿw,      _▄∞""           `"v,              ▀                       //
//                            `ª,_▄"                    `▀▄          ▀   ▄     ▄              //
//                               ╙▄                        ╙▄       ▌   ╒█    ██              //
//                                 ▀                         ▀     ▐                          //
//                        ▓    ▓▄   ▀               ▓    ▓▌   ▀    ╫                    _,    //
//                        █▌   '█    ▌              █▌   '█    ▓   ▓   ▄▄╗≤≤═∞∞═*▓  ,⌐^       //
//                                   ▐                         ╘   ▌         _▄▀" e"          //
//                                    L                         ▌  ▌       ""   Æ             //
//                     ▀█"""""▀▀▀▀*   ▌          `""""""▀▀▀▀%   ▌  ▌           ▀              //
//                       "▀╗_         ▌                         ▌  ▌          ▌   ▐█    █▌    //
//        ⁿⁿⁿⁿⁿ¬~═.__        `▀       ▌                         ▌  ▌         ╫    '`    ▀     //
//                    `¬─_            ▌_,,,,,__                 ▌  ▌     _,≤∞▀ⁿ"ⁿª∞∞╖,_       //
//                        'V_    ╓≤▀""         `"ⁿ═_            ▌  ▌ ,═^`              `"<    //
//                           ª▄▀`                    ª▄         ▌  ▌"                         //
//                 __,__  _,__ ▄                       'w       ▌▄"                           //
//                   ¢▌    █_   ▌                        ▀      █       _                     //
//                   '█    ▀▌    L              ▄    ╒▌   ╙    ▌   ╒█    ██                   //
//                               █              ██    █    ▓  ▐    ╙^   ¬▀"─                  //
//                 ╔,            ▐                          L █                               //
//                  ▀▄""""▀▀▀▀─  ▐            ,             ▌ ▌       ______                  //
//                    ╙▀═        ▐             """"^ª▀%∞∞   ▌ ▌  `"```      `"                //
//                                                          ▌ ▌                               //
//                                                                                            //
//                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////


contract comic is ERC721Creator {
    constructor() ERC721Creator("chippi comics", "comic") {}
}