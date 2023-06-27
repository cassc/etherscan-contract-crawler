// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Boring Art
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                     //
//                                                                                                                                     //
//    lllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllccclllllllllllllllllllllllllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllc::;,'......''',:cllllllllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllllllllllc:,'.......'',,,,,''...,:llllllllllllllllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllllllllllllllllllllcc;'.....',;;;;;;;;;;;:::::,..':llllllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllllllc;'....',;;;;;;;;;;;;;;;;;;;::::,..':clllllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllllllllc:,....',;;;;;;;;;;;;;;;;;;;;;;;;;;:::,..':llllllllllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllllllllllc;'....,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:::,..,cllllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllllllc;'....,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:::,..,cllllllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllllllll:,....',;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;::;'..;cllllllllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllllllllc:'....',;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:::;..'clllllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllll:'...',,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:::,..;clllllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllllc'...'',;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:::;..':llllllllllllllllllllllllllll    //
//    llllllllllllllllllllllllllllc;....',;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;,''......''....,;;;;;;;;;:::,..;lllllllllllllllllllllllllll    //
//    lllllllllllllllllllllllllllc'...'',;;;;;;;;;;;;;;;;;;;;;;;;;,'....',;:cloddxddlc;..';;;;;;;;:::;..,clllllllllllllllllllllllll    //
//    llllllllllllllllllllllllll:....'',;;;;;;;;;;;;;;;;;;;;;;,'...,;:ldkOOOOOOOOOOOOOOd:..,;;;;;;;;:::'.'cllllllllllllllllllllllll    //
//    lllllllllllllllllllllllll;...'',;;;;;;;;;;;;;;;;;;;;;,'..,:lxkOOOOOOOOOOOOOOOOOOOOOx;..;;;;;;;;:::'..:lllllllllllllllllllllll    //
//    llllllllllllllllllllllll;...'',;;;;;;;;;;;;;;;;;;;,'..':dkOOOOOOOOOOOOOOOOOOOOOOOOOOOl..,;;;;;;;;::,..:llllllllllllllllllllll    //
//    llllllllllllllllllllllc;...''',;;;;;;;;;;;;;;;;;,..':okOOOOOOOOOOOOOOOOOOOOOOOOOOOOO0Kx'.';;;;;;;;::,..:lllllllllllllllllllll    //
//    lllllllllllllllllllllc;...''',;;;;;;;;;;;;;;;;'..,lxOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO0KKk;..,;;;;;;;;:,..:llllllllllllllllllll    //
//    lllllllllllllllllllll;...'''';;;;;;;;;;;;;;;'..;okOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO0KXO:..';;;;;;;;:,..clllllllllllllllllll    //
//    llllllllllllllllllll;...'''',;;;;;;;;;;;;;'..:dOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO0KXXk. .',;;;;;;;;'.'cllllllllllllllllll    //
//    lllllllllllllllllll;...''''';;;;;;;;;;;;,..;dOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOKXXk'  ..',;;;;;;;..,llllllllllllllllll    //
//    lllllllllllllllllc,...''''',;;;;;;;;;;,..,okOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOKKXO,   ..',;;;;;;;..:lllllllllllllllll    //
//    llllllllllllllllc,...'''''',;;;;;;;;;'..lkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO0KXO,    ..',;;;;;:,..cllllllllllllllll    //
//    lllllllllllllllc,...''''''',;;;;;;;;..,dOOOOOOOOOOOOOOOOOOkkOOOOOOOOOOOOOOOOOOOOOOOOOO0KXO,     ..'',;;;;:..,llllllllllllllll    //
//    llllllllllllllc'...''''''',;;;;;;;,..;xOOOOOOOOOOOOOkxollclllllllxOOOOOOOOOOOOOkxdoodk0KXO,      ..'',;;;:;..:lllllllllllllll    //
//    lllllllllllll:...''''''''',;;;;;;,..:dkOOOOOOOOOOkdlcccldxxxkdo;;dkOOOOOOOOOxlcccc;,cdkKXO,       .''';;;;:'.'cllllllllllllll    //
//    llllllllllll;...'''''''''',;;;;;'. ,ldkOOOOOOOOxl:cldkkkkkkkkxx::xOOOOOOOOko:coxkko;oOOKXO,        .'',;;;::..;llllllllllllll    //
//    llllllllllc;...''''''''''',;;;;'..:;,;okOOOOOxl:cdkkkkkkkkkkkkkl;oOOOOOOOOl;okkkkkxc:d0KXO,         .'',;;::,..clllllllllllll    //
//    lllllllllc,...'''''''''''';;;;,.'dOOxodOOOOko:cdkkkkkkkkkxxddool';xOOOOOOk:;ddddoooc';xKXO,         ..',;;;::..;lllllllllllll    //
//    llllllllc,...'''''''''''',;;;,..lkOOOOOOOOOd'.;clc;,,,,,coddxol;'ckOOOOOOkl,'...;oo:..dKXO,          .',;;;::,..cllllllllllll    //
//    llllllll;...''''''''''''',;;;..:dxkOOOOOOOOkl'..,,.   .cx00kdolldOOOOOOOOOOxl:,;loc,;oOKXO,          .',;;;:::'.,llllllllllll    //
//    lllllll:...'''''''''''''';;;'.,dddxOOOOOOOOOOkdlc:;,;clooooodkOOOOOOOOOOOOOOOOkkkkxxkO0KXO'          ..,;;;:::;..:lllllllllll    //
//    llllllc. .'''''''''''''',;;,.'dxddxOOOOOOOOOOOOOOOkkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO0KXk'           .,;;;;:::'.,lllllllllll    //
//    llllll;...'''''''''''''';;;..cOkddxOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO0KXk'           ';;;;;:::;..cllllllllll    //
//    lllllc' .'''''''''''''',;;,.'dkkkkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO0KXk.          .,;;;;;::::..;llllllllll    //
//    lllllc. .''''''''''''',;;;..';,lkOOOkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO0KXx.          .,;;;;;::::'.'clllllllll    //
//    lllllc. .''''''''''''',;;,. .';'';,,';oxxxkkOOOOOOOOOOOOOOOOOOOkoldkOOOOOkxocxOOOOOOOO0KXx.          .;;;;;;::::;..clllllllll    //
//    lllllc. .'''''''''''',;;;,. ....   .',:ccccloddxkOOOOOOOOOOOOOOko;;;;;::;;;;cxOOOOOOOO0KXx.         .';;;;;;::::;..:lllllllll    //
//    llllll,...''''''''''',;;;'         .,;:::::::::cloxkOOOOOOOOOOOOOOkdoollodxkOOOOOOOOOO0Okl. .       .;;;;;;;::::;..:lllllllll    //
//    llllllc. .'''''''''',;;;;'         .,;::::::::::::cloxkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOxdooo;  .      .,;;;;;;;::::;..:lllllllll    //
//    lllllll;...''''''''',;;;;'         .,;:::::::::::::::cldkOOOOOOOOOOOOOOOOOOOOOOOOOkdlclll;         .;;;;;;;;::::,..clllllllll    //
//    llllllll,...'''''''',;;;;,.        .,;:::::::::::::::::coxOOOOOOOOOOOOOOOOOOOOOOOkoc:clll;        .,;;;;;;;;::::..,llllllllll    //
//    llllllllc,...''''''';;;;;;.        .,;:::::::::::::::::::coddxxkkkkkkkOOOOkkxxddolc:cllll,       .,;;;;;;;;::::,..cllllllllll    //
//    lllllllllc'..''''''';;;;;;'        .';:::::::::::::::::::::::ccclllllllloollcc::::::cllll,       ';;;;;;;;;:::;..:lllllllllll    //
//    llllllllllc'..'''''';;;;;;,.       .';:::::::::::::::::::::::::::::::::::::::::::::clllll,      ';;;;;;;;;:::;..;llllllllllll    //
//    lllllllllllc'...'''',;;;;;;.       .';::::::::::::::::::::::::;;;;;;;;;;;,;:::::::cllllll'     ';;;;;;;;;:::,..;lllllllllllll    //
//    llllllllllllc,...''',;;;;;;;.      .';:::::::::::::::::::::::;,''..''''''',;:::::clllllol.   .';;;;;;;;;::;..':llllllllllllll    //
//    lllllllllllllc,...''';;;;;;;'      .;;;:::::::::::::::::::::::::::::::::::::::::clllllllc.  .,;;;;;;;;;::,..;clllllllllllllll    //
//    llllllllllllllc;...'',;;;;;;;.     .llcc:::::::::::::::::::::::::::::::::::::::cclllllll:. .,;;;;;;;;;;;..':lllllllllllllllll    //
//    llllllllllllllll;...'',;;;;;:,.    .lddxdlcc:::::::::::::::::::::::::::::::::::cllllllll;..,;;;;;;;;;;'..;lllllllllllllllllll    //
//    llllllllllllllllc'  .',;;;;;;:'    'oddkOkkdolc:::::::::::::::::::::::::::::::cllllllll;..';;;;;;;;;'..,cllllllllllllllllllll    //
//    lllllllllllllllll;.  .',;;;;;::.   'oddkOOOOOkxdolcc:;;;::::::::::::::::::::cclollc:;,...';;;;;;;;,..':llllllllllllllllllllll    //
//    lllllllllllllllll:. . .',;;;;;::.  'oodkOOOOOOOOkxdo:,''..........''''''''''',,''.....',;;;;;;;;,...:clllllllllllllllllllllll    //
//    lllllllllllllllllc. .....,;;;;;:;. 'oddxOOOOOOOOOOxddooo;                      ...';;;;;;;;;;;,...;clllllllllllllllllllllllll    //
//    llllllllllllllllll' .'....,;;;;;:;..;odxOOOOOOOOOOOkxddo,   .               ...',,;;;;;;;;;;,...;clllllllllllllllllllllllllll    //
//    llllllllllllllllll;...'....,;;;;::;..,oxkOOOOOOOOOOOOkxo'   .      .      ..''',;;;;;;;;;;,...;clllllllllllllllllllllllllllll    //
//    llllllllllllllllll:. .'''...';;;;:::..'okOOOOOOOOOOOOOOx,              ...'''',;;;;;;;;;,..':clllllllllllllllllllllllllllllll    //
//    llllllllllllllllllc' .''''...';;;;:::'.'oOOOOOOOOOOOOOOk;       .    ...'''',;;;;;;;;;,..':llllllllllllllllllllllllllllllllll    //
//    lllllllllllllllllll,..'''''...',;;;:::,..lkOOOOOOOOOOOOk;          ...'''',,;;;;;;;;'..,:llllllllllllllllllllllllllllllllllll    //
//    lllllllllllllllllll:...''''''''',;;::::,..oOOOOOOOOOOOOk:         ..''''',;;;;;;;;;...:llllllllllllllllllllllllllllllllllllll    //
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BORING is ERC721Creator {
    constructor() ERC721Creator("Boring Art", "BORING") {}
}