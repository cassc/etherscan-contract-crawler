// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Purple Squirrel Network
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNNXKK00OOOOO000KKXNWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWXKOkdolc:;,,''''''''',,,;:cloxk0XNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMWN0kdl:,'...........................'';clxOKNWMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMNKko:,'......................................';cdOXWMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMWN0dc,...............................................';lkKWMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMWWKxc,..................................................'''';lkXWMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMNOl;.....................................................''''''':dKNMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMNkc'..................','................................''''''''''';o0NMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMNOc'...................'lkxc,.............................'''''''''''''';oKWMMMMMMMMMMMM    //
//    MMMMMMMMMMW0l,.....................'oXWXOo;'.......................''''''''''''''''''';xXWMMMMMMMMMM    //
//    MMMMMMMMMNx;.......................'dNWWWN0o,.................''''''''''''''''''''''''',cOWMMMMMMMMM    //
//    MMMMMMMWKl'........................;OWWWWWWNOc'........'..''''''''''''''''''''''''''''''';xNMMMMMMMM    //
//    MMMMMMW0:'........................'oXWWWWWWWWKl'......'''''''''''''''''''''''''''''''''''',oXWMMMMMM    //
//    MMMMMWO:.........................'c0WWWWWMWWWW0c'''...''''''''''''''''''''''''''''''''''''',lKWMMMMM    //
//    MMMMWO;.........................'cONWWWWMMMWWWNk;''''''''''''''''''''''''''''''''''''''''''''lKWMMMM    //
//    MMMW0:.........................,o0NNWWWWWMMWWWWKc'..''''''''''''''''''''''''''''''''''''''''',oXMMMM    //
//    MMMKc'.......................':xKNNWWWWWMMMWWWWXl''''''''''''''''''''''',loc,''''''''''''''''',dNMMM    //
//    MMNd'......................',lOXXNWWWWWWWMWWWWWXl'''''''''''''''''''''':kNWKo,''''''''''''''''':OWMM    //
//    MWO;......................'ckKXXNWWWWWWWWMWWWWW0:'''''''''''''''''''''cOWWWWO:''''''''''''''''',lXMM    //
//    MXo'....................':dKXXXNNWWWWWWWWWWWWWNx,''''''''''''''''''''l0WWWWWXx:,'''''''''''''''';kWM    //
//    M0:.................'.';o0XXXXNWWWWWWWWWWWWWWW0c''''''''''''''''''''c0WWWWWWWWXOo:,''''''''''''',oXM    //
//    Wx,...............'.',lOXXXXNNWWWWWWWWWWWWWWWXd,'''''''''''''''''''c0WWWWWWWWWWWWXkl;''''''''''''c0M    //
//    No'.............'..'ckKXXNNNNWWWWWWWWWWWWWWWNk;'''''''''''''''''''c0WWWWWWWWWWMWMMWN0o:'''''''''';OW    //
//    Xl'..........'.''';d0XXXXXNNNWWWWWWWWWWWWWWNO:'''''''''''''''''',oKWWWWWWWWWWWWWMMMMMW0o;'''''''';kW    //
//    Xl'''.....'.''''':kXXXXXXNNWWWWWWWWWWWWWWWNO:''''''''''''''''',lONWWWWWWWWWWWWWWWMMMMMMNOc,'''''';kW    //
//    Xl''''''.'''''',l0XXXXXNNNNWWWWWWWWWWWWWWNOc''''''''''''''';cd0XWWWWWWWWWWWWWWWWMMMMMMMMW0c'''''';kW    //
//    Xo'''''''''''',o0XXXXXXNNWWWWWWWWWWWWWWWNOc''''''''''',;cox0XNWWWWWWWWWWWWWWWWWWMWWMMMMMMWk;''''';kW    //
//    Nd''''''''''',o0XXXXXXNNWWWWWWWWWWWWWWWNO:''''''';;coxOKXNWWWWWWWWWWWWWWWWWWWWWWWWMMMWWWWW0:''''':OW    //
//    Wk;''''''''''c0XXXXXXNNNWWWWWWWWWWWWWWNk:''''';lxOKXNNNNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNXOo;'''''lKM    //
//    MKc''''''''';xXXXXXXNNNNWWWWWWWWNWWWWXx;''',cx0XNNNNNNNWWWWWWWWWWWWWWWWWWKxdxxxxxxxxxdol:;,''''',dNM    //
//    MNd,''''''''l0XXXXXNNNNNNWWWWWNNNNWWXx;'';lkKNNNNNNNNNNWWWWWWWWWWWWWWWWWWXx:,'',,'''''''',,''''':OWM    //
//    MWKc''''''',dXXXXXNNNNNNNWWWNNNNNNWXd;',lOXNNNNNNNNNWWWWWWWWWWWWWWWWWWWWWWN0d:,'''''''',',''''',dNMM    //
//    MMWk;'''''';kXXXXXNNNNNNNWWWNNNNNNXd,':xKNNNNNNNNNNNWWWWWWWWWWWWWWWWWWWWWWWNNKko:;,'',','''''',c0WMM    //
//    MMMNd,''''':OXXXXNNNNNNNNWNNNNNNNXd;,cOXNNNNNNNNNNNNWWWWWWWWWWWWWWWWWWWWWWWWWNNNKOxol:,,,',,,,:kWMMM    //
//    MMMMXo,'''':OXXXXNNNNNNNNNNNNNNNXx;,l0XNNNNNNNNNNNNNWWWWWWWWWWWWNNNNNNNNNWWWWWWWNNNX0o;,',,,,;xNMMMM    //
//    MMMMWKl,''':OXXXNNNNNNNNWNNNNNNXk;,l0XXNNNNNNNNNNNNNWWWWWWWWN0kdollccccloodxkOOOOkxoc;,,,,,,;xNMMMMM    //
//    MMMMMWKo,'';xXXXNNNNNNNNNNNNNNNO:':OXNXNNNNNNNNNNNNNWWWWWWN0kxdxxxddl:,'''',,,,,,,,,,,,,,,,:xNMMMMMM    //
//    MMMMMMMXd;',oKXXNNNNNNNNNNNNNNKo,,dXXXXNNNNNNNNNNNNNWWWWWWNXXNWWWWWWNXkc,',,'','',,,,,,,,,:kNMMMMMMM    //
//    MMMMMMMMNk:':OXXNNNNNNNNNNNNNNk;'cOXXXXNNNNNNNNNNNNNWWWWWWWWWWWWWWWWWWN0l,,,,,',,,,,,,,,,l0WMMMMMMMM    //
//    MMMMMMMMMW0o;oKXXNNNNNNNNNNNNXo,,oKXXXNNNNNNNNNNNNNNWWWWWWWWWWWWWWWWWWWN0c,,,,,,,,,,,,,:xXWMMMMMMMMM    //
//    MMMMMMMMMMWNkokXNNNNNNNNNNNNNKl',dXXXXXNNNNNNNNNNNNNWWWWWWWWWWWWWWWWWWWNXo,',,,,,,,,,;o0WMMMMMMMMMMM    //
//    MMMMMMMMMMMMWXKXNNNNNNNNWNNNNKl',dXXXXXNNNNNNNNNNNNNWWWWWWWWWWWWWWWWWWNNXx;,,,,,,,,;lONMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMWWNNNNNNNNNNNNXd,,dKXXXXNNNNNNNNNNNNNWWWWWWWWWWWWWWWWWNNNXd;,,,,,,;oONMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMWNNNNNNNNNNNOc,lKXXXXNNNNNNNNNNNNNWWWWWWWWWWWWWWWWNNNNKo,,,,,cd0NWMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMWWWWNWWNNNXx;:kXXXXXNNNNNNNNNNNNWWWWWWWWWWWWWWWNNNNN0c,,:okXWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMWWWWWNNNKd;oKXXXXNNNNNNNNNNNNWWWWWWWWWWWWWNNNNNNXklokXWMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMWWWWNNKd:dKXXXNNNNNNNNNNNNWWWWWWWWWWWNNNXNNNNNXNWMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWXkokKXXXNNNNNNNNNNNWWWWWWWWWWNNNNWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNNNWWNWWWWWNNWWWWWWWWWWWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PURP is ERC1155Creator {
    constructor() ERC1155Creator() {}
}