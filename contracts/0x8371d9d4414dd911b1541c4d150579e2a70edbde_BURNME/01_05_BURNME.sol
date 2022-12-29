// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Closing Time
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                           //
//                                                                                                                           //
//    ::::::cccccccllllllllloooooooooooo:..    ........',;,..................                                         ...    //
//    ::::::cccccccllllllllooooooooooooo:.... .'',;:::cllllc:;;,'...'''.......                                         ..    //
//    :::::ccccccclllllllooooooooooooodo:...',:llcloollclllllolc:::cllc,.........                                       .    //
//    ::::cccccccllllllloooooooooooooodoc;;:loooollllollcllc;,'',:lloll:,'...................                          ..    //
//    ::::ccccccclllllllooooooooooooodoc;'',;:::;;;;::::;;cc::;,,;:cclloc:;,,,,''''''''................      .. .........    //
//    :::ccccccclllllllooooooooodooool:,...............',;;;:cllllc:::ccc:,..,,,,,,,,,''''''''''.........................    //
//    ::cccccccllllllloooooooooddooc:;.....             .......'',;;,;;,,'....';,,,,,,,''''''''''...''...................    //
//    ::cccccccllllllooooooooddddooc;'.                .......    ..''',;,'....,;;,,,,,,,'''''''''''''...................    //
//    ::ccccccclllllloooooooodddddol;............'',,,,,;:::,....  ......';;'..,;;;,,,,,,,'''''''''''....................    //
//    ::cccccclllllloooooooddddddoc'...';:clc:;:cllooollloxxdl::;'........;cc;.';;;;,,,,,,,''''''''''....................    //
//    ::ccccccllllllooooooodddddoc,..';codddolloddxxkOOkxxkOOkxxxoc;'... .,::,..,:;;;,,,,,,,'''''''''....................    //
//    :cccccccllllloooooooddddddo:..'lddxxddoodxxxkOO00KKKKK00000Okxdo:'..',,'..,c::;;,,,,,,'''''''''....................    //
//    :cccccccllllloooooooddddddo,..:dxddddddddddxxkkkOOO0OOOOO00000Okkxc;,,;,..,cc::;;,,,,,,,'''''''....................    //
//    :cccccclllllloooooodddddddo,..codddddddddooooodddxkkkkkkOO0000OOOOxo:,'...;lccc::;;;;;,,,,'''''....................    //
//    :cccccclllllloooooddddddddo,.'codxxkkkkxxdollodddxxxxkkkOOO000OOOOxoc:'...;lllllcccccc:;;;,,,,,....................    //
//    :cccccclllllooooooodddddddo,.'coxkO0KKK00kxddddxxxxxxxxxxxxkkkOOOkdc:;,..'lOKKKKKKXXK0Oxlc:;;;,'...................    //
//    :cccccclllllloooooooddddddo;.'ldxxkkOOOOOOkkd:,:cccccccclolldkkkkxo:,,'..,lxO00KXNWWWWWWX0xolc:,'..................    //
//    :cccccclllllloooooooodddddoc.,odocclooodxxkx:..,;,;;;;,',;,';oxxxo:,....':;,:okOKXXXXNNNWWNNK0Oxoc;'...............    //
//    :ccccccclllllloooooooooddddo;,:::ccc:::clll;.....',,,,,'''...'ldxo;....,cclx0KK0OkdoodxkO0KXXNNNNX0d;..............    //
//    ::ccccccllllllooooooooooooddc;:odol,.,:c:,,,,;,,''''..'',,,,,;:lddollc;:ddx00kkdlcccccccllodxxkOO0Ox:..............    //
//    ::ccccccllllllllooooooooooddloOXXOl,,:lc;,,'............. ....',:cccc;..;ollol:,;;',ldl;,:::cllooooc'..............    //
//    :::cccccllllllllloooooooooddodxkkkl,,;;'.......,'..........''.. ..;oc'...';:;,......cxo,.,',:ccllol;...............    //
//    :::ccccccllllllllloooooooddxxoccoo;,;,.  .''...................'...,:.   .......';lok0Oo:;'',;clloc'...............    //
//    :::cccccccllllllllllllooodxOkl::c:'',. .','....             ....,,. .,. ..;codkO0KKXXXXKOo;',:clll;................    //
//    ::::cccccccllllllllllloodxxkdc:::'... .,,'...                 ...',. .,cxOKKK00K00OkxdxOK0kl;;:cl:'................    //
//    ::::::ccccccccccccclllllllc:::::,... .,,''.                    ...,:. .lxxdolccllllccllodkOkl:;cl:.................    //
//    ;::::::cccccccccccc:;,'...;:;:c;. ...,c,...        .....        ..':,..,c::;;::;;,,;:cllloxkOkxdo;.................    //
//    ;:::::::ccccccccc:'.. ...':c:cc;.  ...,''.      .   ......      ...'.. '::''''''.. ...;:cloxkO00d;.................    //
//    ;:::::::ccccccc:'.  ..  .cocc:;,.  ....''.      ..........      .'... .'cc:cldxkkoc;'.'',::ldk0Kk:'................    //
//    ;;;:::cccccclc;.   .....:xxolc;'.  ....',,.      ...'...        .'.....:xOOOkkkkOO00OOkkxddxkO000d;................    //
//    ;:cc;'',,,,;;'.  .......:oooddoc'.......';,.                  ..'.....'colllc::::coxkOO0KXXXNXKOxl,................    //
//    ::clc,...'','...........':codkkxl;'......';;'.              ..,,'.....;cc;;,,,,,;:cclodxkO0KXXKOo;.................    //
//    ...'locccllc'............':oxO0KKOoc;,'....,;;,...      ...';;,......'::,....   ...;ccllloxkOOkdc'.................    //
//    .  .lxdoddd:.............':oxOKXXKK0Oxl;'....',;;;,,,,,;;;;,'......',,.            .':cccclllddl,'.................    //
//    '. .cxxdddl'.....   ...  .;odxxkOO0000Od:,.......';::;;,.........','.''..  .        .;:cclolllo:''.................    //
//    ;,..ckkddo;........  ... .,ccc:clodkOOOkdl:,'.....,,''''.....',;;,.. .;:,'...... ...',;:lddoll:,...................    //
//    ;c,'cxkddl,.. ..    .    .cc;'',;:codooolccc,''',,,'''',;;:::coddl;. .'cl:;'.... .,',;:clddocc;....................    //
//    coc':xkxdc'..           .;ol::ldxxoc,'',,,,,;;:cccccccclddolcldkOx:.  ..clc;,'.. .',,;:cldddol;....................    //
//    oxl,;xkxd:.....        .;oddodxOOkoc:::c:;,,''.....',,;::::::ccloc.     .;cl:,.   .';:clloxxxo;....................    //
//    coc,:dxxo,.  ......  .'codxkkxxdoooodxkOkoc::;,'..',,;::ccccc:::,.        .:l:.   .,;:cloodxxd;..................      //
//    ;cl::oxxl...   .....':oollooolc;;;;:cokOkdlcccclllllcccc::;'....           .,:.   ';:cclooodxd;.................       //
//    ,:::cdxd:.....    .'ldl:;;:;;,,,;::cllllllccclllc:;,,,'..                    ..  .;:ccclllodxkx:............           //
//    odxxdol:. ...     'cl:;;;;;::cc::::::::::::;;;,,,,;;,.                    ..... .':cclllllodO0KOc..........            //
//    xxxxoc,...  .   .,lol:;;,',;;;;;,,,,,;::;;,,;;::;;;'.                   ..........;lloooooodk0K0x;.........            //
//    ,'',:c,...     .:ddolcc:;'....',,;;::::ccllllll:;,..                  .............:lllooooodkkkkc..........           //
//    ...,c;. .  ....;cc:;,,,;:;......',,;;::::clllc:,.                    ..............'cllloollooooxd;...........         //
//    ,:coc.   ..  .;cc::::;;;::;.....'.......'',,'..                     .............. .:ccllllloooldxd;....;;,'.......    //
//    lloo;. ...  .;ccllccc:;,''''',,;'.                                  .'...........  .;::ccccloddoodkxc'..,;'........    //
//    lll:.  ..  .,:;:llllc;,''',;ccc'. ...                              ............... .';:cccclodxxdodkko'..,'.           //
//    llc'  ...  .,;;;:::;,''',;:lll,  ...'...                           ...         ......,:clllclodxxddxkko;;;'.......     //
//    cl:. ....  .';;;;,,'',,;:clol,. .. .....                           ..         ....';,;:cllllccldddddxkkkkd:.....'.     //
//    cl:,,,.   ..';,,,,,,;:ccloddl'.    .......'..                     .'.        .... .';;;cloollcclodddddxxxkdc......     //
//    ccccc,.  ...',,,;;::cllodddddo,. ....  ....,'..                  .'..,:::,...'.... .,;;:cllllccclooolodddxxdc,.        //
//    ccclc;.  ...',;::cclllodddddddc....    .....',,'.               .'.'clllc;..''..    .',;cllllcccclllllooddxxdo:..      //
//    cclc:;'.....';::cclllodddolc:::'........''''',,,,,..           .'.':ccoc'.''....     .',:cllllcc:cllccclooooddo:'..    //
//    cccc;,'...''',;::;;:ccc:;,,'',''..   ........'...',,'.        .'.'lo:c:'.'..  ..   .  .';:clllcc:::ccc::clooooooc'.    //
//    ;;;;,,''..''..''''''''..''''..          ............','.     .'',:ddo:'''..            .,:cccccc::::cc:::clooolll:.    //
//    ,,,,',,,,,'............'',;:'           .............'..     ''':ldd:,,'.            . .';:ccccc::;;:c::::llollclc'    //
//                                                                                                                           //
//                                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BURNME is ERC721Creator {
    constructor() ERC721Creator("Closing Time", "BURNME") {}
}