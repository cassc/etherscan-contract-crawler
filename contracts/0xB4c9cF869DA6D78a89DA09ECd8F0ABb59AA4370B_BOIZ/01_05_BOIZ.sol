// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: da boiz
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////
//                                                          //
//                                                          //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMWNNNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMXdcccokkk0XNWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMNk:,/mb',,..,:lloxO0KXXNWMMMMMMMMMMMMMMMMMMMM    //
//    MMMMWKdl:;;,,'......,;,;::clook0NWMMMMMMMMMMMMMMMM    //
//    MMMMMN0dc:::;;;;,'...,,,''',,,',:okXWMMMMMMMMMMMMM    //
//    MMMMMMWXOdc:;;;:;;'.''''''...,,''',cxKWMMMMMMMMMMM    //
//    MMMMMMMMMNkolc::c:;;;'''...........',ckNMMMMMMMMMM    //
//    MMMMMMMMMW0dlccloolc:;;,,''.....''..',;oKWMMMMMMMM    //
//    MMMMMMMMMW0o:;;::ccc::::;;;;;,''',,,,,,,cdkKWMMMMM    //
//    MMMMMMMWXOdllllllooolcc:;;;cc:,'..,:;;,,,',ckNMMMM    //
//    MMMMMMN0xlcc:;:lolllollcc:clc;'...;::;,'...':kNMMM    //
//    MMMMMWKxdolc;';oxxddoolccccc;''...;:,'......,cOWMM    //
//    MMWX0kxxddkdlodxdolccccccc:;,,'...........';:ckWMM    //
//    MMMNXXKKKXNXXNWWXOdc::::cc::;,,,;:cloxOOkddkO0NMMM    //
//    MMMMMMMMMMMMMMMMMMWXK0kxxkkkkOO0XXNNWWMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMWWWWMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                          //
//                                                          //
//                                                          //
//////////////////////////////////////////////////////////////


contract BOIZ is ERC1155Creator {
    constructor() ERC1155Creator("da boiz", "BOIZ") {}
}