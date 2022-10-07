// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Simplicity Diaries
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                             //
//                                                                                             //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNK0OkkkO0KXNNWWWWWWWWWWWWWNNNNNWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWXOxolcccccccclodxk0NWWWNX0kxddoooddx0NWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWNKxlccccccccccccccccccokOxolccccccccccccdKNWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWKxcccccccccccccccccccccc::cccccccccccccccclkNWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWW0occccccccc:::::::::::::c::ccccccccccccccccccxNWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWNOlccccccc::::ccccccccccc:::;::::::::::::::::::ckXNWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWNklcccccc::cccccccccccccccc:::;:cccccccccccc::c:::cdk0NWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWXxccccccccccccccccc:::::::::::::::::ccc::::::::::::::::oONWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWXkoccccccccccccccc::::::::::cccccccc::::::::::::::::::c::::dXWWWWWWWW    //
//    WWWWWWWWWWWWWNKxl::cccccccccccc::::::ccccccccccccccccc:;:cccccccc:,,,;cllc::o0NWWWWWW    //
//    WWWWWWWWWWWWXklc::cccccccccc::::::ccccccc;,'...,lk0KK0kccoxkO00x;.    .o0K0koxNWWWWWW    //
//    WWWWWWWWWWWXxcccc:cccccccccc:::;:ldxxkkd;',c,....,OWMWKOKWWMMWk..'.,o; .dWMN00NWWWWWW    //
//    WWWWWWWWWWXxccccccccccccccccccc::ldOKN0; .,c,;00, ;0Kxld0XXNW0,  ..'c,  ,dxxONWWWWWWW    //
//    WWWWWWWWWNkccccccccccccccccccccc::::clc'..','.::'.,:::::cllool,.....'',;:lkKNWWWWWWWW    //
//    WWWWWWWWW0lcccccccccccccccccccccccc:::::::::::::::;;:cccccccccccccccccldkXWWWWWWWWWWW    //
//    WWWWWWWWKoccccccccccccccccccccccccccccccccccccc:::cccccccc::::::::::lkXNWWWWWWWWWWWWW    //
//    WWWWWWN0occccccccccccccccccccccccccccccccccc:::ccccccccccccc:ccccccccd0NWWWWWWWWWWWWW    //
//    WWWWWNOlcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccclxXWWWWWWWWWWWW    //
//    WWWWWKo:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccdXWWWWWWWWWWW    //
//    WWWWWKlcccccccccccccccccccccccc::::::::::ccccccccccccccccccccccccccccccccxNWWWWWWWWWW    //
//    WWWWWXd:cccccccccccccccccccc:;;;;;;;;;;;;;;;:::::ccccccccccccccccccc::::;:dXWWWWWWWWW    //
//    WWWWWNOcccccccccccccccccccc:;;::::;;;:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;::dXWWWWWWWWW    //
//    WWWWWWXd:cccccccccccccccccc;;::::::::::::;;;;;;;;:::::::::::::::::::;;;cdOXWWWWWWWWWW    //
//    WWWWWWWKocccccccccccccc::cc::;;;;;;;;;;;;;;;:::;;;;;;;;;;::;;;;;:;;::;:xNWWWWWWWWWWWW    //
//    WWWWWWWWKxlccccccccccccc:::ccccccccccccc:::::::;;;;;;;;;;;;;;;;;;;;:oxOXWWWWWWWWWWWWW    //
//    WWWWWWWWW0o;,;:ccccccccccccccccccccccccccccccccccccccccc:::::::::cdONWWWWWWWWWWWWWWWW    //
//    WWWWWWWWNo''..',;:::::ccccccccccccccccccccccccccccccccccccccccodOKNWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWXo''''''',,;;;:::::::::::ccccccccccccccccccccc::codxOKXWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWXo'''''''''''',,,;;;:::::::::::::::::::::::::;,,:dOXWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWXl'''''''''''''''''''',,,,;;;;:::::::;;;;;,,'''''',:oONWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWXl''''''''''''''''''''''''''''''''''''''''''''''''''',lONWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWXl''''''''''''''''''''''''''''''''''''''''''''''''''''',lONWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWXxlllllllllccccccccccccccccccc::::::::::::::::::;::;:;;;;:xXWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXNXXXXXXXXXXXXXXXXXXXXKKKKNWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//                                                                                             //
//                                                                                             //
//                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////


contract XO is ERC721Creator {
    constructor() ERC721Creator("The Simplicity Diaries", "XO") {}
}