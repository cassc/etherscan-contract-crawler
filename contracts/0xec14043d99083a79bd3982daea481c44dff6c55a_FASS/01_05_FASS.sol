// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Free Association
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    oooooooooddooooc'.......',cloooodol;.........,............''',,,,,,,,,;,..,:;;,''......,;;;;;;;;;,...        ......'''''    //
//    oooddooooddooool,.',,,'',:loooodddd:'........'............'''',,,,,,,,,'..;;;,,'''''..';;;,'',;;,....      .....'',,,,;;    //
//    ooddddddddddooooc;;,',;coddllodxxxd:'...............''''..''''',,,,,,,,..';;;,,'''''..'''..',;;'....     ....''',,;;;;;:    //
//    dddddddddddddlc::;..,clllooodxxxxxd:'..............'''cl,.',,,,,,,,,,,,..,:;;,''''....'...';;,''....   .....''',;;;;;;;;    //
//    dddxdddddxdxxl,,,,...',,;:::::ldxxo;''.............'';x0o,',,,,,,,,,,,'..;:;,''......'''',;,''''...  .....''',,;;;,;;;;;    //
//    ddxxxdddddxxxoolll:,;lcc:;,,';ldxo:,,'''...........'';xK0o,',,,,,,,,,,'..;;;,''.''....',;,...''''.. .....',,',,,,,,;;;;;    //
//    dddxddddxxdxxdddooc:cdolc::;;:odl:;;,,,''...........';xKXKd;',,,;;;,,;'.';;;,,'''.....','..',,''...........''',,,,;;;:::    //
//    ddddddddxxxdddddollllllcc:;coolc::;;;,''''...........',xKKOc'',;;,;;;;'.';;;,,'''..'..''.,;,,,,'.. ........''',,;:::::::    //
//    ddddddddxxxddddoolllllccc:col::::;;;,,''''.............'lxo'..',;;;;;;,.';;;,,''......',:;'',,,'....,,;;;;;;:;;::::::;;;    //
//    ddddddddxxxdddooooolllcc:::::;;;;;;,,,''''...............'....:c;;;;;;,.';;;,,'.....''';;'.',;,'..';:::::::cc:c::::::;;,    //
//    ddxddddxxxxdddooooolllc:::;;:;;;;,,,,,,'''......... .......;lxXKo:::;;,.';;;,''.....'';;'.',;,,'..';::::::cc:::::::::;,'    //
//    ddxddddxxxdddddoooollcc::;;;;;;;;;,,,,,''''........  ..;,.;kXXNWXxc:::;'';;,,''''''.',;'.',;;;;,'.';::::::::::::::::;,'.    //
//    dxxddddxxxxddddoollllcc:::;;;::;;;,,,,,,''''......... .,odldO0XNWWKdc::,';;;,,,'''''',,,,,;;;;;;,'';:::;;,;;;;:;;;,''...    //
//    dddddddxxxxdddooooollcc:::;;;;;;;;,,,,,,''''.......''...:c;,;ckXWWMNklc:,,;;;,,,,','',;;,,;;;;;:;;,;::::::;;;;;,'''''...    //
//    dddddddxxxxddddoooollcc::::;;;;;;;,,,,,,''''......'',,'',,'''',lONWMWKdc;,;::;;,,,,,,;:;,;;;;;::::;;;:::c:;;;;,'''''''''    //
//    dddddddxxxxddddooolllc:::::::;;;;;,,,,,,''''''....',:cllooooolcclxKWWMNkl;;:::;;;;;,;;:;;;;;;;::::::::::::;;,'''''''''''    //
//    dddddxxxxxxxdddooollccc:::::::;;;;,,,,,,,,''''''.',codxxkOO0000OOkkOXWMWXxccc:::;;;::::::;;;::::::::;;;;,,,'''''''''''''    //
//    dddxxxxxxxxxdddoooollcc::::::::;;;;;,,,,,,,,,'''';codxkkkOO000000OOkkOKWMW0occ:::::::::;;,,;::;;;;,,,,,,,''''''''''''''.    //
//    ddxxxxxxxxxxddddooolllcc:::::::;;;;;;,,,,,,,,,'',clldxkkkkOOkkkOOOOkkxxOKWWKdcccc:::::;;;;:::;;,,,,,,,,,,'''''''''''''''    //
//    xxxxxxxxxxxxxdddooollllc::::::::;;;;;,,,,,,,,,',;:;;clodddxxdxxxkkkkkkxxkOKNKoccc:::cccccccc::;,,,,,,,,,,,''''''''''''''    //
//    xxxxxxxxkxxxxxddoooolllc:::::::::;;;;;,,,,,,,,,,,;,..',;:cccclodxkkkkkkxxkkOX0occcclllllcccc::;,,,,,,,,,,,''''''''''''''    //
//    xxxxxxxxkkxxxxdddooolllcc::::::::;;;;;;;,,,,,,,,';cc::cloxkkxkOOxdxkkkkkxkxxxOxccloollllccccc:;,,,,,,,,,,,,'''''''''''''    //
//    xxxxxxxxxkxxxxxddooollllcc::::::::;;;;;;;,,,,,,'',;:,';cloxOOOkddkkkkkkkkxxdoooooooollllccccc:;,,,,,,,,,,,,'''''''''''''    //
//    xxxxxxxxxkkxxxxxddoollllcccccc::::::;;;;;;;;,,'',,,',cdxdodxxxxxkkkkkkkkkkxoloooooolllllccccc:;,,,,,,,,,,,,,,'''''''''''    //
//    xxxxxxxxxxxxxxxxxddoollllllcccc:::::::;;;;;;;,',;:;,:dO0OOkxxkOkkxxdxxxkOOdloodoooollllllcccc:;;,,,,,,,,,,,,,,''''''''''    //
//    ddxxxxxxxxxxxxxxxxdddoolllllllcccc::::::;;;;;,;;;:;;:dO0OOOOkkxxxxxxxxxxkOkkkxdoooollllllcccc:;;;;,,,,,,,,,,,,,''',,,,,'    //
//    ddxxxxxxxxxxxxxxxxxxddooolllllllcccccc::::::;,'',;;,,lOOkkxollodkkOOOkxxkkkkkkxdooollllllcccc:;;;;;;,,,,,,,,,,,,,,,,,,,'    //
//    xxxxxxxxxxxxxxxxxxxxxddddoooooollllllccccccc;'..''...:xkdl:::::coddxkkkxkkkOkxddooolllllccccc:;;;;;;;,,,,,,,,,,,,,,,,,,'    //
//    xxxxxxxxxxxxxxxxxxxxxxxxdddddoooooooollllll:,,,;;;,,:oxol:;;;;:cloodkkkkOkxddoddooollllllcccc::;;;;;;,,,,,,,,,,,,,,,,,,,    //
//    xxxxxxxxxxxxxxxxxxxxxxxxxxxxdddddoooooooool;,;:cclodkkkkkkxdddkkkkkkkOOOkxxxxxdoooooolllllccc::;;;;;;;;,,,,,,,,,,,,,,,,,    //
//    xxxxxxxxxxxxxxxkkkkkkkkxxxxxxxxdddddddddddo:;;:cloxkOOOOOOO0000000OOO00Oxddxkxdoooooollllllcc::;;;;;;;;;,,,,,,,,,,,,,,,,    //
//    xxxxxxxxxkkkkkkkkkkkkkkkkxxxxxxxdddxxdddddoc;;:cldkkOOOO000KKKKKK000000kdolooxxxddoooolllllcc::;;:;;;;;;;,,,,,,,,,,,,,,,    //
//    xxxxxkkkkkkkkkkkkkkkkkkkkkkkkkxxxxxxxxxxxxo:;:cldkOO000000KKKKKXXKKKKK0kocccloddddoooolllllcc::::::;;;;;;,,,,,,,,,,,,,,,    //
//    xxxxkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxxxkxxxxkd:;cloxkOO00KKKKXXXXXXXXXXXKOxlcccldxddddoooollllccc:::::;;;;;;;;,,,,,,,,,,,,,    //
//    xxxxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxl:cloxkkO00KKXXXXNNNNNNXXXKOxolccldxdddddoooolllccc::::::;;;;;;;;;,,,,,,,,,,,    //
//    xxxxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkdccoddxkOO0KKXXNNNNNNNNNXK0Oxdocclxxxxddddoooolllcc::::::::::;;;;;;;,,,;;;;;,    //
//    xxxxxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkdccodxkOO00KKXXXNNNNNNXK0Okkxdoodxxxxxddddooolllcc::::::::::::;;;;;;;;;;;;;;    //
//    xxxxxxkkkkkkkkkkkkkkkkkkOOOOOOOkkkkkOkkkOkkOkdcccoxxkO000KKKXXXXXXK00OOOOxxxxkxxxxxdddoooolllcc::cc::::::::;;;;;;;;;;;;;    //
//    kxxxkkkkkkkkkkkkkkkkkkOOOOOOOOOOkkkOOOkkkOkkOkkxollooxxkkOOO000KKK0OOOOOkkkkkxkxxxxddddoooollcccccccc:::::::::::::;;::;;    //
//    kkkkkkkkkkkkkkkkkkkkOOOOOOOOOOOOkkOOOOOkkkkOOkkkkkxdooooddxxxkkOOOOOOOkkkkkkkkkkxxxxxdddooolllcccccccccc::::::::::::::::    //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract FASS is ERC721Creator {
    constructor() ERC721Creator("Free Association", "FASS") {}
}