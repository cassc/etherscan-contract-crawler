// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BonsAI by Gordon Berger
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    lllllllllllllooooooooooooooooooooooooooooooooooooddooooooooooooooooooooooooooooooooooooooooooooooO88    //
//    kllllllllllllllllloooooooooooooooooooooooodxooooo8.AI.8oooxdddoooooooooooooooooooooooooooooooooooooW    //
//    klllllllllllllllllllloooooooooooooooooooolloolllccccloddodoc:llcloooooooooooooooooooooooooooooooooOW    //
//    klllllllllllllllllllllllllllllllllolllllllcc:;::;;::ccl11oolcc::llllooooooooooooooooooooooooooooooOW    //
//    klllllllllllllllllllllllllllllllllll:,;;red.:,;::::;;::::cc:c::::;;;:cloooooooooooooooooooooooooooOW    //
//    kllllllllllllllllllllllllllllcc::llooc;,;:lc:,,;;;,,'';::c;,;;'''''';looooooooooooooooooooooooooooOW    //
//    klllllllllllllllllllllllllloc;,77',::cc;,;;;;,'...'..','...''..'''..',:cclloooooooooooooooooooooooOW    //
//    Ollllllllllllllllllllllloloooc;''''';,...''.....',;'.'.  .;:,'''..',',;;:looooooooooooooooooooooooOW    //
//    Olllllllllllllllllooooolooololc;''......'..'''...','...   .''.....'''.',;;:5loooooooooooooooooodooOW    //
//    Ollllllllllllollooooooollllll:;;,,,'... .''.';:;:lolcc;   ......',,;;,,;'.'coooooooooooooooooodddooW    //
//    Oolllllllllllooooooool:;;;;;,''...''.....''.';;cccccdko,..';cccloool::green,;coooooooooooooooodddooW    //
//    Oolooolloollooooooooooc;'.;;..'',',::::cc:;''',::,,:ll:,;;',::ccccc:;,;:;,,;3cooooooodoooooooodddooW    //
//    Ooooooooooooooooooooollc;'.'..,,;:;:::::;;;'........'','';;::;,,,,,;,.'.....;looodddodddoooodddddoOW    //
//    Ooooooooooooooooooooc;;;:;,'..,'.',;:;,',,','.......    ..';,,....',........;::clodddddddddddddddoOW    //
//    Ooooooooooooooooooool:2,,,','..,.....,:::loodxdddoooc.    ........ .......,..',;lxdddddddddddddddddW    //
//    0oooooooooooooooooooooolc:::;,;;;:clolccldxkkdlo;....   ...........;'...',,..,;lddddddddddddddddddOW    //
//    0ooooooooooooooooooodooooollllcllc:::;;:blue.'..       ...  ...'. .::,;,';c,..,codddddddddddddddddOW    //
//    0oooooooooooooooddooc::don.:;,,;:,,;;'',,,'..  'l;,,;cll:'.,clcloc;'..';:;::...,coddddddddddddxdddOW    //
//    0doooooooooooddooll::,''';:;,',,,'',,......   :kkkkkkkxoc;,:c:cddoc'....'......:ooooddddddddddxxddOW    //
//    0doooooodddddddol;9,'.','...,;'''.,,,;,.,'.   .lod0OOkkkk.black:;;:;,'....'',,',,;:clddxxxxxxxxxxxxW    //
//    0ddddddddddddddddl;..............,:clodxd:.     .;4:lkkkkkkkkkxxkkkkxdoclodxxxdlcllodxxxxxxxxxxxxx0W    //
//    0dddddddddddddddddollc;,'.',,:clodxkkkkkkkdlc;.     .;dkkkkkkkkkkkkkkkkkkkkkxxxxxxxxxxxxxxxxxxxxxx0W    //
//    Kddddddddddddddddddddxxdddddxxxxxxxkkkkkkkkkkko.      .:dkkkkkkkkkkkkkkkkkkkkkxxxxxxxxxxxxxxxxxxxx0W    //
//    Kdddddddddddddddxxxxxxxxxxxxxxxxxxkkkkkkkkkkkkkd,.      .lkkkkkkkkkkkkkkkkkkkkkkkkxxxxxxxxxxxxxxxx0W    //
//    Kxddddddddddddxxxxxxxxxxxxxxxxxxkkkkkkkkkkkkkkc.         'xOkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxxxxxxxkx0W    //
//    Kxddddddddxxxxxxxxxxxxxxxxxxxxkkkkkkkkkkkkkkkc.          .dOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk0W    //
//    Kxdxxxxxxxxxxxxxxxxxxxxxxxkkkkkkkkkkkkkkkkkkx;      ...';okOkkOkOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk0W    //
//    Kxxxxxxxxxxxxxxxxxxxxxxxkkkkkkkkkkkkkkkkkkd:'.      :kkkOOkkkkkkOOOOOOOOkkkkkkkkkkkkkkkkkkkkkkkkkk0W    //
//    Kxxxxxxxxxxxxxxxxxxxkkkkkkkkkkkkkkkkkkxol;..      .;xkkkkkkkkkkOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkkkkkk0W    //
//    KkxxxxxxxxxxxxxxxkkkkkkkkkkkkkkkkkO0KOo,..       ,cdOkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkk0W    //
//    KkxxxxxxxxxxxxxkkkkkkkkkkkkkkkOOOkkkkdc'.     .'lkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkKW    //
//    XkxxxxxxxxxxkkkkkkkkkkkkkkkkOOOOOd:;'...;c::lodkOOOOOOOOO000000000000000000000OOOOOOOOOOOOOOOOOOOOKW    //
//    XkxxkkkkkkkkkkkkkkkkkkkkkkkOkolodxl'.  ;dxOxldkkkOOOO0000000000000000000000000000OOOOOOOOOOOOOOOOOKW    //
//    XkxkkkkkkkkkkkkkkkkkkkOkOxoxx' ..;l,   ..';. ....''',;;;cldO000000000000000000000000OOOOOOOOOOOOOOKW    //
//    XkkkkkkkkkkkkkkkkkkkOOOOOkloKk:ldccoc:cc:l;.. .','....    .;23::cdO0000000000000000000OOOOOOOOOOOOKW    //
//    XOkkkkkkkkkkkkkkkkOOOkdlll:,colccc::,''','.'....88...... . ....   .:ollllok000000000000000OOOOOOOOOK    //
//    XOkkkkkkkkkkkkkOkOOOOd::c:;'.';;;;,;,''''...................','.....'''..;k00000000000000000O00O0OKW    //
//    XOkkkkkkkkkkkkOOOOkd_BonsAI_by_GordonBerger_oooooooooooooooooooloddodddddooodd0000000000000000000000    //
//    kkkkkkkkkkkkkOOOOOOd,.....................''''''''''''''''''''''''''''''.':x0000000000000000000000XW    //
//    NOkOkkkkkkOOOOOOOOOOo....................................................;kK00000000000000000000KKXW    //
//    N0OOOOOOOOOOOOOOOOO0k;...................................................lKKKKKKKKK00000000000KKKKXW    //
//    8888OOOOOOOOOOOOOO00O:...................................................dKKKKKKKKKKKK00000000KK8888    //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BonsAI is ERC721Creator {
    constructor() ERC721Creator("BonsAI by Gordon Berger", "BonsAI") {}
}