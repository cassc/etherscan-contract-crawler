// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Reddyrivatives
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                 //
//                                                                                                                 //
//     These are all pieces lovingly and thoughtfully reinterpreted by me for various friends and collections.     //
//    Thank you for taking the time to read this; it actually means a lot. When I was in highschool the first      //
//    wave of art that was most meaningful to me in terms of making connections was sticker art. I traded          //
//    Trading and creating characters and sharing them with people all over the world was an incredible            //
//    experience and these remixes bring me immediately right back to that nostalgic place for me. I love          //
//    making characters in as many themes and motifs as possible. Exploring my imagination is my favorite          //
//    exercise to work out my brain and I feel my creativity getting stronger with each one. each character        //
//    is a new puzzle for me to solve and create.                                                                  //
//                                                                                                                 //
//                                               ,,                                                                //
//                                              ▄▀▀▄                                                               //
//                                             ▄▌▒▒░▌                                                              //
//                                            ╒▌▒▒░░▐▌                                                             //
//                                            █░░▒░▒▒█µ                                                            //
//                                      ▄█   █░▒░░░▒▒░█   ▐█                                                       //
//                                     █░▀, ▐▌▒░░░░▒░░░█ ,█░█                                                      //
//                                    ▐▌▒░▀██░░░░░░░░░░██▀░▒▐▌                                                     //
//                                  ]▄█▌░░▒░░░▒▒░▒░░░░░░░▒▒▒▒█▄▌                                                   //
//                                   ▀█▀░░▒░▒▒░▒▒▒░░▒░░▒▒░░░▀██                                                    //
//                                     ▀█▌▒░░░░▒░▒▒░░░░▒░░░█▀                                                      //
//                                      █▀░▒▒░▒▒▒▒▒▒░▒░▒░░▀█                                                       //
//                                    ▄█░░░▄▒░░▒▒▒▒░▒░░▒▐░░░▀▄                                                     //
//                      ,g▄╖,,,    ,█▀░░░░██▀░░▒░▒░░▒░░▀██░░░░▀█╖    ,,,╓g▄,                                       //
//                    ,▄▌▒▒▒▒▒▒▒██▀░▒░▒▒░░░░░░▄█▄░░░█▄▌░░░░░▒░░░░▀██▒▒▒▒▒▒▒▒▌,                                     //
//                  ▄▒▒╝,╔@╦╦,╙╬▓▓██░▒▒░░▒░░▒░▀█░░▒░█▀▀▒▒▒░░░▒░░███▓▓╜,╦╦#╦,╙▒▒█                                   //
//                  █▒▓╓▓,M"ⁿ.╙Ç╟▒▓▒▒░▒▐████▄▄▄▄▄▄▄▄▄▄▄▄████▌▒░▒░▓▒▓ ╝,^"ⁿ,╚╗╙▒█                                   //
//                  █▒L╟ ╟ Ç╙/ ╝╓▓▓▌▒░░▐▌█▓█▒▒█▀▀██▀▀█▒▒███ █▒▒░░█▓╗╚Ç\╙  ╟ ▒ ▒▓                                   //
//                  ▓╢@ ▓,"mmM"╓▒╢▓█░▒░░██▀███▌▒▒██▒▒▒████▀█░░▒░▓▓╣▒W`ºmm╜,φ╛╔╣▓`                                  //
//                   `▀▓╗╥╢@@▓▒▓▌`└█▌▒▒▒░▀█████▄▄███▒████▄▀░▒▒▒▄█╜`▀▓▒▓@@▓╥g▓█`                                    //
//                      ▀▀▀██▓▓▀  ▄▀▓█░░░▒▒░▀████▀▀████▀░░░░░░██▀█  ▀▀▓██▀▀▀`                                      //
//                          ▐█▄,,█░░░░▀█░░░▒▒▒▒░░░░▀▀░▒░▒░░░█▀░░░░█▄,µ█▀                                           //
//                             ▀▀█▓W░░▒▒▒░░░░░░░▒▒░█░░░▒░░▒░▒░▒░╖Ñ█▀▀                                              //
//                                `██▀░▒▒░▒░░▒░▒▒░█▌▒░░░░▒░░▒░░██▀                                                 //
//                                 █░░▒▒▒░▒▒▒░░▒▒██░▒░▒░░░▒░░▒▒░█                                                  //
//                                ▐▌▒░▒▒▒▒▒░▒▒░░█▀███░▒▒░░▒▒░░▒░▐▌                                                 //
//                                █░▒░▒▒░▒▒░▒▒░▐█▄▌▐█▄▌▒░▒▒▒▒▒░▒░█                                                 //
//                                █▒░░░▒░░▒▒░▒▒░░█   █░▒▒▒▒▒░▒▒▒▒█                                                 //
//                                █▒▒░▒░░▒▒░▒▒░▒▀▀█ █░░▒▒░░░▒░░▒░█                                                 //
//                               ██▌▒░░▒░▒▒▒░▀██▄█▌▐█▄▄▄░▒▒░▒▒░░▐██                                                //
//                            ▐█▀▀░█░░░▒▒░▒░▒░░█K  ▄█▀░░░░░░░░▒▒█░▀▀█▌                                             //
//                              ▀▄░░▒▒░▒░▒▒░░█▀▀█▄█████░░▒░░░░░▒▒░▄▀                                               //
//                                █▀▀█▄▄▄░░░▒░▒░▐▀░▒░▒░░░░░▄▄▄██▀█                                                 //
//                               █     `╙▀▀▀▀▀██▀▀▀▀▀█▀▀▀▀▀╙`     █                                                //
//                               █         ▄█▀        ▀█▄         █                                                //
//                                "▀▀▀▀▀▀"                "▀▀▀▀▀▀`                                                 //
//                                                                                                                 //
//    ---                                                                                                          //
//    asciiart.club                                                                                                //
//                                                                                                                 //
//                                                                                                                 //
//                                                                                                                 //
//                                                                                                                 //
//                                                                                                                 //
//                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract RDYRMX is ERC1155Creator {
    constructor() ERC1155Creator() {}
}