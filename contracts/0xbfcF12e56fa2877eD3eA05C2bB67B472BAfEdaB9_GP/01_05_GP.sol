// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Glamping Pass
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////
//                                                                                   //
//                                                                                   //
//    MWWWWWWMMMMMMMMMMMMMMW0c'.....................................''';cd0NMMMMW    //
//    WWMMMMMMMMMMMMMMMMMMMMWXkl,'.''....'.....................'.....''.'';lkXWWW    //
//    WWMMMMMMMMMMMMMMMMMMMMMMMW0o;'...'...........................''.'..'..':xXW    //
//    WMMMMMMMMMMMMMMMMMMMMMMMMMMWKd:'.........'....................'''..'.''.,oX    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXx:'.'''''''''''''................''..''''.'o    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXx:'.'..'''''.''''..............'''''''''.,    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKd;'''.''''..''...............'''''''''.'    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKko,'''''''''................''''''''''    //
//    MMMMMMMMMMMMMMMMMMMMMMMWWWWMMMMMMMMMMMNO:'''''.'.................'......''.    //
//    MMMMMMMMMMMMMMMMMMMMMMXdccldxOKNWMMMMMMW0:.''''.'..........................    //
//    MMMMMMMMMMMMMMMMMMMMMMK:.....',ckNMMMMMMKc...'''''.........................    //
//    MMMMMMMMMMMMMMMMMMMMMMWk;'..'.':kWMMMMMM0c''..''''.........................    //
//    MMMMMMMMMMMMMMMMMMMMMMMWKkollokXWMMMMMMMWKd:'..'''.........................    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMWWMMMMMMMMMMMMMWKo,...'.........................    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWOc'.'.........................    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKc''.........................    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO;..'..''...'''''...........    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXl.....'....................    //
//    oooooooddddxxkkO0KKXNWWMMMMMMMMMMMMMMMMMMMMMMMMNo....''....................    //
//    .............'''',,;:clodxkOKXNWMMMMMMMMMMMMMMMK:.'''''''''...''...........    //
//    .''.'''...'''''..'''......'',;:loxOKNWWMMMMMMMNo'.'''''''''''''''..........    //
//    .''''''''''''''''''''''..'''''....',:clx0NWMWXo,..'''''''''''.'''..........    //
//    .''''''''''''''''''''..''''''''....''..',cdOx:'..''''''.''''''''...........    //
//    .''''''''''''''''''''..'''''.'''''..'''''.'''',:::;,'..''''.'''............    //
//    ..'..'..........''''.....'''''''''.''''....'.'oKNNX0kl,''''''''''''''''''..    //
//    ...............................''''''.''...''.;kWMMMMWOc'...'''.''.........    //
//    ................................''''''''''..''.:0MMMMMMXOxoc,'.'....'''....    //
//    ..............................''''''''''',,,'''c0MMMMMMMMMMNKx:'.''''''''''    //
//    .....'........................''.''.'..'o0K00O0XWMMMWXkxkXWMMWXo,.'''.'''''    //
//    .'''...........................''''.'''';xNMMMMMMMMMKl'.'cKMMMMNd'.'.''''''    //
//    ..''............................'''''.''.,xNMMMMMMMMXo;,,oXMMMMMK:.'..''.'.    //
//    '..'''''........................'''.'''.'.;OMMMMMMMMMWK0KNMMMMMMXl.''.''.''    //
//    ,.''''..'''''''................'..''...''.'xWMMMMMMMMMMMMMMMMMMM0:.'''....;    //
//    l'.'.'.'''''''''.................''''''''.'dWMMMMMMMMMMMMMMMMMMNd'.'''''.,d    //
//    Ko,..''''''''''..................''''''''.'dWMMMMMMMMMMMMMMMMMNx,''.'''.,oX    //
//    MXx:'..'''''''''.................''''''''.'dWMMMMMMMMMMMMMMMMMNx;'....'ckNW    //
//    MWNKkl;,'.'..'''....................'''''.'dWMMMMMMMMMMMMMMMMMMWKo,';oOXMMW    //
//    WWWWWN0xl;,'..............................'dWMMMMMMMMMMMMMMMMMMMMXkkKNWWWWW    //
//                                                                                   //
//                                                                                   //
//                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////


contract GP is ERC1155Creator {
    constructor() ERC1155Creator("Glamping Pass", "GP") {}
}