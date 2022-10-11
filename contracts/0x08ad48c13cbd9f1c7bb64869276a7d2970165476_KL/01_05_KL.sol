// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Folklore Dreams
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWMWWWWWWWWWWWWWWWWNNNXXXXK0KK0O0NWWWWWWWXXNWWWWWWNX0kxkKNKOXWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWNNNWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNNXK000KKK00OkdoOXNXNNWNKKNWNWWWNKxlc:coxx0WWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWNNNWWWWWWWWNNWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNXXKOxk0KKKK0Oxddk0kxxkO000KK000O0klc:coOxxKWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWNNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNXK0OkkOKKKKK0OO0KX0kdllodxxdl:;,,lOOllkX0kKNWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWMWWWWWWWWWWNNXKK0000KKkk00O0XWWX0xc:;,'''''''',cxkk0X00NWNWWWWWWWWWWWNXXWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWMMWWNNNNNXKKKKKKK00XXxc;,'''''''''''''',;okO0XNNNWWWWWWWWWWWXxONW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNXK0KNWWWWWWWWWWWWWWWMMWWWWWWWWWWWWNNNNNXX0kdc,,'',,,,,,,,,''',,,,;lk0KWWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWNXK0Oxdlc:;,;lxk0NWWWWWWWWWWMMWWWWWWWWWWWWWWWWWWNOl;:::;;,,,,,,,;::;,''',,,,;ckXWWWWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWNKOxoc:;,,''''',',,,,;cxKWMMWWMMWWWWWWWWWWWWWWWWWWWWXxc::::;;,,''''',:cc:,'',,''''',:d0NWWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWXOdl;,,'',,,,'',',,,',,,,,,:o0NWMMMWWWWWWWWWWWWWWWWWWWKd:;,,,,,,,'',,,',,,,,''',,,,,''',,;o0NWWWWWWWNKKNW    //
//    WWWWWWWWWWWWXOdc,,,,,,,''',,,',;,,,,,,,;;,,,cdOXWWWWWNNNNWWWWWWWWWWNOc,,,'''',,'',,,,''''''',,'''''''''',,:dKWWWWNXXkxXW    //
//    WWWWWWWWWN0oc;,,,,,,,,''''',,;cc;',,,',;;,',,,;:d0NWNNNNNWWWWWWWWWKo;,'',,,''',;::c:;'''''''''''''''''',;,',ckXNWN0KNNNN    //
//    WWWWWWWWNk;,,,'''',,,,,,'''',;;;,''',,,'''''''''';oOXWWWWWWWWWWWNk:,,,'',;,''',;::cc:,'''''''''''''',;,'''''';kNWWWNNNNN    //
//    WWWWWWWW0c,''''''',;,,,'''''','''''',;,,,,,,,,,,'',,:d0NWWWWWWW0o;;,''',,,''''''',,,,''',,'''''''''',,,'''''',c0NNNWWWNW    //
//    WWWWWWWNx;',,''''',,,',,,''''''''''',;,,;;;,,''',,,',,;oONWWWXx:,,,''',,,,''',,,''''''',,,''''''''''''''''''';;l0NNNWWWW    //
//    WWWWWWN0c'''''''''''''',,,''''''''''''''',,,,'''','''''';lO0kl,,'''''',,,''''''''''''''','''''''''''''''''',,,,,lKNWWWWW    //
//    WWWWWWNx;''''',',,'''''''''''''''''''''''''''''''''''',,'';;;,,'''',''''''',;;;;;;,,;,,'''''''''''''''''''',,'',,oKWNNNW    //
//    WWWWWWNk;''',;,,,,,'''''''',,,,,,''''''''''''''''''''''''''''''';:;,''''',:coolcc::c:;,''''''''''''',,,;,,',,''':xKNNXXN    //
//    WWWWWWKo,'''',,,''''''''''',,,,''''''''''',,;,,;;,,,'''''''''''',;,'''''';cllolcc:::;,''''''''',,'''''',,'''''''cOXNWNNW    //
//    WWWWWNOc'''''''''''''''''''''''','''''''',;::;,;::::;,''''''''''''''''''',;ccllcc;,,,,',,'''''',,'''''''''''''';xXNNWWWW    //
//    WWWWWWXkc'''''''''''''',,,'''''''''''''',,,;;;;,,,;;:,''''''''''',,,'',,''',,,,;,,,,,,',,,'',,''''''''''''''',:xXNNNWWWW    //
//    WWWWWWNXOc,,'''''''',;,,::,,,,,''''''''',,;;;;;;,;;;;,'''''''''',,,,''',',,,,'''''',,,''''''''''''''''''',,',ckXNNWWWWWW    //
//    WWWWWWWNXO:..'''''''',,,;;,,,,,'''''''''',,,,;;,'''''''''''''''''''''''''''''''''''''''''''''',,,,,,,,,,,,;;lOXNNWWWWWWW    //
//    WWWWWWWWNXkc'',;,''''',;;,,,''''''''''''''''''''''''''''''''''''''''''''''','','',,,,,;;;:::::::::::cccccclx0NNNWWWWWWWW    //
//    WWWWWWWWWNN0o,,,'''''''''''''''''''''''''''''''''''''''''''''''',,,',,,,;;;:::cclllllooodddddddddoooooooloxKNWWWWWWWWWWW    //
//    WWWWWWWWWWNNKd;'''''''''''''''''''''''''''''''''''''',,,,,,,,,;;;:::ccllooooooooooolllllllllllcccccccccccd0NNWWWWWWWWWWW    //
//    WWWWWWWWWWWNNKx:'''''''''''''''''''''''','',,,,,;;;:::::::cccccllollllccccc::;;;;;,,,,,,,,,,,,,,,,,,,,,,cOXNNWWWWWWWWWWW    //
//    WWWWWWWWWWWWWNXk:''''''',,,,;,,,,;;:;;;;;;;;;;;;;:::::::::::;;;;;;;,,,,,,,,''''''''''''''''''''''''''',:x0KXNWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWNXOl:;;;;;;;;;;;;:;;;;;,,,;;;,,,,,,,,,,,,,'''''''''''''''''''''''''''''''''''''',,,,''',:kKXNNNWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWNX0dc;;::;,,,,,,,,,,''''''''''''''''''''''''''',,''''''''''''''''''''''''''''''',,,,,,:kXNNNWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWNN0d;,''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''',''''''''''',',:xXNNNNWWWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWNN0o;,''''''''''''','''''''''''''''''''''''''''''''''',,''',,''''''',,'',;;,'''',;ckXNNNNNNNWWWWWWWWWWW    //
//    WWWWWWWWWWWWWWWWWWNN0d:,'',''''''''''''''''''''''''''''',,',,,''',,,,,',,',,,,''''''''''',;,,'''',cOXNNNNNNNNNNNWWWWWWWW    //
//    NNNWWWWWWWWWWWWWWWWNNKd;''''''''''''''''''''''''''''''',,,''',''''',,''''',,,,,'''''',,''''''''',ckXNNNNNNNNNWWWWWWWWWWW    //
//    WWWNNWWWWWWWWWWWWWWWNNKd:,,,''',''''''''''''''''''''''''''''''''''''''''''''',,''''''''''''''',,lOXNNNNNNNNNNWWNNNNWWWWW    //
//    NNKkONWWWWWWWWWWWWWWWNNKxc;,,'''''''''''''''',''''''''''''''''''''''''''',,','''',,,''',,,'',,,ckXNNNNNNNNNWNWWNNNWWWNWW    //
//    NNXKKXNNNWWWWWWWWWWWWWNNXkl;,',,''''''''''',,'''''''',,''''''''''''''''',,;;,,''''''',,,,,',;;ckXNNNNNNNNWNNNNNNNWWWWWWW    //
//    WWWWNNXXXNWWWWWWWWWWWWWWNXOl,,,,''''''',,,,,,,,'''''',,''''''''',,''''''',,;,''''''''''''',;:lkKNNNNNNNNNWWNXXXNNNNWWWWW    //
//    WWWWWWWNNWWWWWWWWWWWWWWWWNXOl:;,''''''''',,,''','''''''''''''''',,,''''''',,,''',,,''''''',,cxKNNNNNNNNNNNNNNNNNNNNNNWWW    //
//    WWWWWWWWNWWWWWWWWWWWWWWWWWNXOdc;,'',,,'''''''',,,''''''''''''''',,'''''',',,,''',,,',,,,,',;dKXNNNNNNNNNNWNNNNNNNXNNNWWW    //
//    WWWWWWWNNNWWWWWWWWWWWWWWWWWNXkc,',,,,''''''''',,''''''''''''''''''''''''',;,,''''''',,,,,;:o0XXNNNNNNNNNNWWNNXXXXXKXNWWW    //
//    WWWWWWWWNWWWWWWWWWWWWWWWWWWWNXk:,,,,''''''''''''''''''''''''''''''''',''',,,'',,,'''',,,,;oOXNNNNNNNNNNNNNNNNXXXX0kKNWWW    //
//    WWWWWWNWWWWWWWWWWWWWWWWWWWWWNNKk:,,,,',,'''''''''''''''''''''''''''''''''''''',,,'''',,',cOKXNNNNNNNNNNNNWWWWNNNNNNNWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNKk:,,,',,'''',,:;,''''''''''''''',,',''''''''''''''''',,,ckKXNNNNNNNNXKKXNNNNNNNNNNWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNKx:,''''''''',;,'''''''''''''''',''''''''''''''''''''',ckKXNNNNNNNNNXO0XNNNNNNNNNNWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNKd;,'',,''',,,''''''''''''''''''''''''''''''''''''',,ckKXNNNNNNNNNNNXNNNNNNNNNNNNWWWWWW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNXKx:,','''''''''',,'''''''',''''''''''''''''''''''',ckKXNNNNNNNNNNNNNNNNNNWNNNWNWWWWWNW    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNXKx:,'''''''''''''''''''''''''''''''''''''''''''',ckKXNNNNNNNNNNNNNNNNNNNWWNNNNNWWWWNN    //
//    WWWWWWNNNWWWWWWWWWWWWWWWWWWWWWWWWWNNKkc,'''''''''''''''''''''''''''''''''''''''''',ckKXNNNNNNNNNNNNNNNNNNNNNNNNNNNWWWNNW    //
//    WWNNWWWNNWWWWWWWWWWWWWWWWWWWWWWWWWWNNKkl,'''''''''''''''''''''''''''''''',,,,'''',ckKNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNWNNN    //
//    NWNNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNXOl,'''''''''''''''''''''''''''''''''''',;;lOXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNWWWW    //
//    NNNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNXOl,''''''''''''''''''''''''''''''''''',;lOXNNNNNNWWWNNNNNNNNNNNNNNNNNNWWWNNWWWWW    //
//    NNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNXOo;'',,,''''''''''''''''''''''''''''',lOXXNNNNNNNWNNNNNNNNNNNNNNNNNNNNNNNWWWWWW    //
//    NNNNNNNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNX0o;'''''''''''''''''''''''''''''''',lOXXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNWNNNNNNNN    //
//    WWWNNNNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNX0d;'''''''''''''''''''''''''''''',o0XNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNX0d;'''''''''''''''''''''''''''';d0XNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNWNN    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNX0d:,,''''''''''''''',;,'''''';dKXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNX0xo:,''''''''''''''','''''':xKXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNWWNNNNNN    //
//    WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWNNXKx:''''''''',,''''''''''':xKXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNWWWNNNNNN    //
//    WWNWWWWWWWWWWWWWWWWWWWWWWWWWWWNWWWWWWWWWWWWWWWNXKx:,,'....'''''''''''',ckKXNNNNNNNNNNNNNNWWNNNNNNNNNNNNNNNNNNNNWWWWWWNNN    //
//    WNNNWWWWWWWWWWWWWWWWWWWWWWWNNNNWNNWWWWWWWWWWWWWNXKx:''.........'''',,;lkKXNNNNNNNNNNNNNNWWWWNNNNNNNNNNNNNNNNNNWWWWWWWWNN    //
//    WWWNNWWWWWWWWWWWNNNNNNNWWWNNNNNNNNNWWWWWWWWWWWWNNXKkl:,'..''''....'',lkKXNNNNNNNNNNNNNNWWWWWNNNNNNNWNWWWWNNNNWWWWWWWWWNN    //
//    NNNNNNWWWWWWWWWWNNNNNNNWWWWWWWWNNNNNWWWWWWWWWWWWNNNKOdl:'.''''.....'cOKXNNNNNNNNNNWWWWWWWWWWNNNNNNWWWWWWWWWWWWWWWWWWWWWW    //
//    NNNNNNWWWWWWWWWWWNNNNNNWWWWWWWWWWNNWWWWWWWWWWWWWWWNNXOdc,.........,lOKXNNNNNNNNNNWWWWWWWWWWWWWWWNNWWWNNWWWWWWWWWWWWWWWWW    //
//    NNNNNWWNNWWWWWWWWNNNWNNNNNNWWWWWWWNNWWWNWWWWWWWWWWWWNX0o,....''..,o0XXNNNNNNNNNNNWWWWWWWWWWWWWWWWWWWWNNWWWWWWWWWWWWWWNNW    //
//    NNNNNNNNNNWWWWWWNNNNWWNNNNXNWWWWWWNNNNWWWWWNNNNNWWWWWNX0o,...''.,o0XNNNNNNNNWNNNNWWWWWWWWWWWWWWWWWWWWWNWWWWWWWWWWWWWWNNN    //
//    NNNNNNNNNNWWWWWWNNNNNNNNNNNNNNNNNNNNXXNWWWWWWWNNNNWNNNNX0d;'''';d0XNNNNNNNWWNNNNNWWWWWWWWWWNNWWWNNNNNWNNNWWWWWWWWWWWWNNN    //
//    NNNNNNNNWNNNNWNNNNNNNNNNNNNNNNNNNNNNNNNNWWWWWWWNXNWNNWNNNKkl::cxKXNNNNNNWWWWWNNNNWWWWWWNNWWNNNWNNNNNNNNNNWWWWWWWWWWWNNNN    //
//    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNWWWWNNWWWWWWWWWWWNNX0kxkKXNNNNNNNWNWWWNNNNNNNNNNNNNNNNNNNNNNNWNNNNNWWWWWWWWWWNNNN    //
//    NWWWWWWNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNWWNXNNNWWNNNNWWWWWNNNNNNNNNNNNNNWNNWWNNNNNNNNNNNNNNNNWWNNWWWWWNNNNWWWWWWWWWWNNNN    //
//    WWWWWWWNNNNNNWWNNNNNNNNNNNNNNNNNNNNNNNWNNWWWWNNWWNNNWWWWWWWWWWNNNNNNNNNWWNNNNNNNNNNNNNNWWWWNNWWWNNWWWWWWWWWWWWWWWWWNNNNN    //
//    WWWWWWNNNNNWNNWWNNNNNNNNNNNNNNNNNNWNXNWNNNWWWWWNWNWWWWWNWWWWWWNNNNNNNNWWNNXNNNNNNNNNNNNWWWWWNNWWNNNWWWWWWWNWWWWWWNWNNNNN    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract KL is ERC721Creator {
    constructor() ERC721Creator("Folklore Dreams", "KL") {}
}