// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Scriptomania by Godfrey Reggio
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////
//                                                                    //
//                                                                    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWMMMMMMMMMMMMMM    //
//    MMMMMMMMWKkxddooooollllccccccccccc::::;;,,;;;:;:d0WMMMMMMMMM    //
//    MMMMMMMMO'                                       .OMMMMMMMMM    //
//    MMMMMMMMx.             ..'''',,,,,''..           .oWMMMMMMMM    //
//    MMMMMMMMk.           .,;::::::::::::::,.          cNMMMMMMMM    //
//    MMMMMMMMO.        .',;;;;;;;;;;;;;;;;::;,.        cNMMMMMMMM    //
//    MMMMMMMM0'      ..,;:;;;;;;;;;;;;;;;;::;;;.       lNMMMMMMMM    //
//    MMMMMMMM0'     .;:;::;;;;;;;::;;;;;;;;:::;,.      lWMMMMMMMM    //
//    MMMMMMMMO.     ':;;;;;;;;;;;::::;;;;;;;::;;,.     oWMMMMMMMM    //
//    MMMMMMMM0,     ,:;;;;;;;;;;;;;;;;;;;;;;;;;;;;.   .xMMMMMMMMM    //
//    MMMMMMMMK,    .;::;;;;;;;;;:;;;;;;;;;;;;;;;;;'   .xMMMMMMMMM    //
//    MMMMMMMMK,     ,:::;:;;;;;;;;;;;;;:;;;;;;;;;:;.  .kMMMMMMMMM    //
//    MMMMMMMMK,     .;:;;:;;;;;;;;;;;;;;;;;;;;;;;:;.  .kMMMMMMMMM    //
//    MMMMMMMMX:      ':::;;;::;;;;;;;;;;;;::::;;;;.   .kMMMMMMMMM    //
//    MMMMMMMMWo      .';::::::;;;;::;;;::::::;;:;.    .kMMMMMMMMM    //
//    MMMMMMMMWd.       ':;;::::;;;;;;;;::::::::,.     .xMMMMMMMMM    //
//    MMMMMMMMMk.        ..',,,,:::::::::::::;;'       .xMMMMMMMMM    //
//    MMMMMMMMM0'               ..............         .xMMMMMMMMM    //
//    MMMMMMMMMXc.                                ..  .:0MMMMMMMMM    //
//    MMMMMMMMMMN0xdddoolllllllllloooooooooddxxxOO00OO0NMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                    //
//                                                                    //
////////////////////////////////////////////////////////////////////////


contract GRS is ERC721Creator {
    constructor() ERC721Creator("Scriptomania by Godfrey Reggio", "GRS") {}
}