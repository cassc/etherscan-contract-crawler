// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: DJ Pants & Joe Howl
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    .. .....         ........  ..;:'.,col;,::clxko,..cxkO0KKKkl:cokK0OKKKXKXNNKOKWWNNXKXKOo,.................................''.............',;::ccc:cc:;c    //
//                               ..,,..':ooloxkxxkOk:..':dO000Oo:oxkOK0OKNNNNXNXK0XWWW0kO0OOk:..... .                      ....''.............',,;:::;;::c:c    //
//                              .....',;clc::lollldkdc,..'loloo;,cxkkkOOKNNWWNXKKKXNNXOdxkk00x;.....                      ....'''..'........'',,'''',;;;;:::    //
//                             ......;llc:;'...',;:odoc;'..,,',,'',;::coxO0000OxxxkOO0K0OkO0KX0l....                     .....'''...'.....''..''''..',,,',,,    //
//                             .....,:c:,'........';;;;,,..............';:llccc::::ldOKKOO00XWWKc....                  ................''''.....''....',,,,;    //
//                            ... .';:,....  .............................'''''',,;:cdOKKXNNWWWW0;.... .            ..................',,'..''..''''''''',;:    //
//                            .....;:,.                 .......................',,;;;lkKXWWMMMMMNo.....           ..................',:::,''',,,,,,;,,''',:l    //
//                             ...';;.                    ..    ..............',;;;;;cxKNMMMMMMMWx.......        ...................,cl:,'''',;;,,,,'''''';c    //
//                              .'';'.                          ..............,;:::::lkKWMMMMMMMWk'......        ...''.............',::,''''',;;,'',,,''.',;    //
//                             .',,;.                         ...............':cc:cclx0XWMMMMMMMMK:......         .............'',;,',,'.''.',,,''''.....',;    //
//                             .,'',.                          ..............,cllllox0XWMMMMMMMMMNo......          .............',,'......''''.'''.....',,,;    //
//                             .;..'.                            ...........,:loooox0XWMMMMMMMMMMMO'.....          .......................'''''',;'...',,,''    //
//    .                        ',..'.                            .....':lodxkO00OOO0XWMMMMMMMMMMMMK;......    .      .....................','..';;,......,;;    //
//    ..  ......              .''..'......                     ....;coxOO00KNNNWMWWWWWMMMMMMMMMMMMWd......               .............',''','..,;,'.....',;;    //
//    ...............     .......';::;,'.......             .....,;:;,''.'';:clkXNNWMMMMMMMMMMMMMMM0;.....             .  ...........',''';c:,'',;;'.''..',,    //
//    ....',,,'''.....   ......':l:,......'',;;'..  .      ...''...':lodddlc;,:ldkkO0NWMMMMMMMMMMMMXc...... ...        ..............''..';c:,,,,:;'',,'''',    //
//    ...',,,,,,''.............';;,;::,......,ldl'..........';'.':dKWWMMMMWNKkooddddxXWMMMMMMMMMMMMWd.......   ...     .......................'''''':c;'...'    //
//    ...',,,'''..............'lOKKXNNOl;'....'o0O:........;:,'l0XNWMMMMMMMMMWXkdxkxkXMMMMMMMMMMXKXNXl.............    ................'''''..',''..,,,,,...    //
//    ..',,,,'...............:OXNNXNNKklccc,..',dXKo,....;lo;,xNWWWWMMMMMMMMMMMNxlxOkXMMMMMMMMMMXkd0WXo'..........       ..........';;;;;c:,..',,,...',cl:,'    //
//    ..',,,,'..............;kK0OOOOOkxdddxxc'.,dK0dc;;;:cdxcdNWWWWMMMMMMMMMMMMM0dd0NWMMMMMMMMMMWXXNWMNO:................   ......';c::;;;,'..',;;'....',;'.    //
//    ...',,,,'.............cO0OkxxxddxkO0KKkc,cOXOdooooxk00xOWWWWWMMMMMMMMMMMMM0doOWMMWWNNWMMMMMMMMMMMW0c'.''...................',,'.''......'','..',',;,'.    //
//    ...',,,'..........'''':OK0Okkxolodk0XNXd:cxNN0xdodkKXN0ONWWWWMMMMMMMMMMMMWk:oKWMWWWNXWMMWWWMMMMMMMW0l,,,,'''',,''..........'..................',,,;,''    //
//    '...................'''l0NX0OkxoooxOXNXd''dNWXd;',;lx00OKWWWNWMMMMMMMMMMNkod0WMWWNNNNWMMMMWNNWMMMMW0dc;;;;;;::;;;,''.....'''....'...'..'''.....'''::;;    //
//    ;,'''''''......',,,,;,.':kXNXXXKkc;dKXO:'cKWXo..  ...;lxO0XWWMMMMMMMMWNklo0WWWWWWNNWWWMMMWX00NWMMMWKkoc:cccclcc::;''....'''.....''','..';;,....'';cc;,    //
//    ;,',,,;;;,,'.....',:c:;,''cxKXNXKxcoko;:dXWXd'.   ...;lxOkkO0KXNNNX0kdlokNWWWWWWNNWWWWMMMWXOkKWWMMX0Odc;:loollc;;;;;,,''''....''''',''',;;,'''',;coo:,    //
//    ;,'',,;;::;,,'','';cllc;;;..';:c:::;:lkKNXOl,.     ..,odkkolloddxxddxOKNWWWWWWWWWWWWWWMMMWXkd0NWMWKxkxlccoooolc::::::;,,''..'''''''''.',;;,,,;;;:cllc;    //
//    ;'''',,;;;;,;;;;,,;colccclc'.     .,lxkkdl;'..    ..,ldloOd;,,:lxO0KXXXXXXNNNXNWWWWWWWMMWN0dxO0NWNOdddoloooccllllllccc:;,,,;;;,,,''..';::;,,,;;:cll:,,    //
//    :;,,,,,,;;;:clcc::clccc::ll;.    ......'''..... ...cOX0kx0Ol'...':loxkOO0KXXXXNNWWWWWMMWNXkdxkO0K0kdddddddoollodddolllc;,,;:::cc:;,,',;:;,''';:ldoc:;,    //
//    oolcc:::cclloolllodxdolcc::;..    ...........:;.';dKWWN00XKo,.....,:ldxkO0KKXXNNWWWWWWNXK0xxkOOK0kxxxxxddxxxdddxxdddoool:;:::;:c:,'',,;;''..':oollcc:;    //
//    xxxxddlclodxxdoloxkkxdoddlc:;....  ..........''.':d0NWNKK0xc,'....';coxkO0KXXXNWWWWWWWXOkkkOkkOKKOkkkkkxxxkxdddxxddooodlc:c::;::c:;,,,,,'...',:;;;;;,,    //
//    dollllc:cloxkkkxxxkOkxddxxdlc;..     .............,oKNNKkdc;,''''',;coxO0KKXXXNWWWWWWN0kO00kxxkO0OkkkOkkxxkxddoddodddooc:::;,,;;;;''.......'',,,,''',,    //
//    ;:::;,,,;:lxkOOkxxkOkkkkkxdoolc'.         ......',':x0KKOxoc:;,,,;;:ldk00KKXXNWWWWWWWWNNNXOkkkkkkkkxxxxxdddoooollcccc::;,'.....''.........',;;,;;;,,;;    //
//    ccc:;;;,;:oxkkOkxkkkxxxkkxooddxo'.       ........'..;coOOkkkxdl::::clxO0KKXXNWWWWWWWWMMMNxc:::::::;;;;;;,,,,,,,'''''...........''.........'',;;;::;;;;    //
//    ddooolcccoxOOOOOkxollcloxxxxxkkkc.    .............',,;lxOKKK0kxxdoodxOKXXNNWWWWWWWWWMMMKc....'''''''''''''''''''''''''..............''.....',;::c::;;    //
//    odxkxooooooddool:'.'''',;;::cc::;..  ....'''',cllldkkxxkk0KKXXK000Okxk0XNNWWWWWWWWWWWMMMKc...............................''''''''...''''''..',;:clc::;    //
//    ;,;:;,,,,,''''...................... ...;lc;,,:ccclooddkO0KK0K00KXX0O0XNWWWWWWWWWWWWWMMMKc.....''',,,'',,,,,,,,',,,,',,''',,,,,,,'''',,,,''',;:clolc:;    //
//    .......................................,;,..     .....'codxxxkk0NNXXXXWWWWWWWWWWWWWWMMMMKl;;;;;:cclllcclllolllccccc:::;;,,,,,;;,,''',,;;,,''';:coolc:;    //
//    .......................................,'........'',,:codxxxxkOKNWNNWWWWMMMMMWWWWWWMMMMMW0o::cccllooollllooooollllc::;;,,,,,,,,,,'''',;;;,''',;:looc::    //
//    '...........................''''',,:l:,,'.......:loddxkkkkkk0KXNWWMWWWWMMMWWWWWWWWMMMMMMMWKocccllooollllloooollccc::;,,'''',,,'''''''',;,,'..',:colc::    //
//    ...................',,,,;;;;;:::ccoddl;;:;'.....';:oooodxkKXNWWMMMMMMMMMMWWWWWWWWWMMMMMMMMNOlccclllllccclllllcc:;;,,'...''''''''''''''',,,'..',;:clc::    //
//    ,,'''',,,,'''''''',;:ccc::ccccccccloc:;;:oo;'......',;:lkKNWMMMMMMMMMMMWWWWWWNNNNWMMMMMMMMN0d::::cccccccccc::;,,,'''....''''''''''','',,;,'..',;:clc::    //
//    ::;;;;;;::;;;;;,,,;:cllcccccccccloolcc:,,cdd:,.......,cOXWMMMMMMMMMMWWWWWWNNXXXXWMMMMMMMMMMWNOdc:;::;;;,,,,'''...........',,,,,,,,,,,,,;;;,'.',;:cc:;;    //
//    cc:;;;;::::;;;;,,,;:cllcc:cccclloooll:;,'';odoc,''';:lOXWMMMMMMMMMWWWWWWNNXKK0KXNWMMMWWWWWMMMMWKxlc:;,''''...............'',,,,,'''',,,;;;,..',;:cc:;;    //
//    cc:;;;;:::::;;;,'',,;:c::::::cclccc::,'....';lkOkkkO0XNWMMMMMMMWWWWWWWNNXK00OO0KNNNNWWWWNWMMMMMMMWNK0kxdl;'..............'',,,,,,,,,,,,;;:;,',;;:c:;,;    //
//    cc:;,;;::::;;,,'''',,;;;;::::ccccc:;,''...:dl''cdO0XNNNNNNNNNNNNWWWNNNNX0Okkxxk0KXKKXXNXNMMMMMMMMMMMWWWWNKOo:,...........'',,;;;;,,;;,,;;:;,',;;;::;,;    //
//    cc:,,,;:::;;,''....'',,,,,;;;;,,'''.....'dXMO,.....,:loodxOO0KXXXXXXXKK0kkxxddxOOO0KKXXXWMMMMMMMMMMMMMMWWWMWWXOxoc;'.....'',,,;;;,;;;;,;;;;,,,;;;:::;;    //
//    :;,'',;;:;;,........''',,,;;;;;;,,,,''..,kNM0;........',:ldxkOO000KK0OkxddoooodxxkO0KXNWMMMMMMMMMMMMMMMMMWWWMMWWWWNKOxlc;,,,,;;:;;;:::;;:::;;,,,;;:ccc    //
//    ::;'',;;::;,''......',,,,,;;,,,;;:::;'',,,ckx'.........';:lodxxxkkkkxdollccclllooxOKXNWMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWNK0kdlc::;;;::::;:::;;;;;;:::::    //
//    ;;;''',,;;;,'................'',;;,,'..':ol,... .......',::cllcllooolc:;;;;:::coxOKXNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWWNXKOdlcc:;;;::;,,;:::c::;:    //
//    ;;,'.',;::;'..........'',,;;:::;;,''..',o00o'... .......'',,,;;;:::;;,,,,,;::ldkKXNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWMMMWNXK0kxollc:;;;;;;:ccc    //
//    ;;,'.',,;;,'''.....',;:::::::;;,'''...',cxkOx,..............''',,,,,''',,:lox0XNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWWMMMMMMMMMWWNKOxl::::::ccc    //
//    ;;,''.'',;;;,''.',;;;;;,'',;::::c::;;;,;cloxOo,................'''''',:ok0XNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWWWWWWWWWWWWWWWWMMWWWWMMWNkc:::::::    //
//    ;;;,'''',;;;;,,,;,,''......'',;;:ccclolc:cllkOd;,,................':oOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMMMWWWWWWWWWNNWWWWWWWWNXXXXXNNWNXNWMMWMMNOl:clllo    //
//    ...........,;,'''..........',''''',;:loo:odcd0XOl;,.............,ckXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNNWWWWWWWWWWKOxk0XX00OOOkkkOO0KXXXNWWWWWWMMWKxodddx    //
//    ''.......'''...............';;,,''''',;::lo:ckXNKkl:.......';cox0NMMMMMMMMMMMMMMMMMMMMMWWWWWMMMMMMNXXNWWWNNXXNXxccllollllloooddxkkOKNWWXKNWWMMMMN0kxkx    //
//    '.......';,''...............,;::c:,'...':kd:clkKWWWX0xoodk0KNWMMMMMMMWWWMMMMMWWWWWWWWNNNNNWWWMMMMWNKKXNWWNXK0K0o:::::ccc:ccclloddx0NWWXKKNNWMMMMMNkooo    //
//    ........;:;:;'''..........'',;:clol:,'..:0Ollolo0NWMMMMMMMMMMMMMMWWNK00KNWNNXXXNXXXXXXXXNNWWMMMMWWX000KXWWXK00kl:ccc::ccccccclood0NMWNXXNNWWWWMMMMXxoo    //
//    ......':lc:lc,,,,,,'''...',;;;::::cc:,'.;OO:,:oxkOKNWWMMMMMMMMMWNK000K00Okdxk0KKKKXXXXNNWWWWWWWWWNKOOkddKWKkxdolclllllllllllolld0WMWNNNNWWWWNXWMMMMN0O    //
//    ......;ldl:od::::;;,,''..',,,,'''',;;,'',xO:..':odk0KXXNNNNNXXXK0OOkxoc;;;::cldO0KXXXXXNNNNNNNNNNNXOdc::dXKoccllollloodddxdocco0WMMWNWWWWWMMX0XMMMMMNK    //
//    .....'coooldkl:cc::;,'...........''''''',xKo'....',:cloooooolc::;;,',,,,,;;:::cloxkO0KKKKKXKKK00OOko:cc:l0NOlcclloooddxOkxl:cd0WMMWNNWWWMMMWKOKWMMMMMN    //
//    .....:ooooxxOx::::;;,'..............'''',oXk,........''''''''''''''''''',,,;;::::cclolodddddoooooool::cccdXXxcclloodxkkxl:;:o0WMMMWWWWWMMMMWKxkNMMMMMW    //
//    ....:odoolkO0Ol;:;,,'.................'',lKK:....''...''''''''''''',,',,,,;;;;;;:;:::::::::cclllooddl:codoON0oloodddddlcc:coOWMMMMWWMMMMMMMWKxkNMMMMMM    //
//    kdlcoddollOK0Kd;;,,'''.'''...........'''':OXo'..''''''''''',,,,,,',,,',,,;;;;;;;;;;;;::::::cccloddddo::oxddKWKkxdol:;;,:looONMMMMWWWWMMMMMMN0xkNMMMMMM    //
//    MWKxddddooOX0Kk:,,,'''.........'........';xXx,..'',,,,,,,,,,,,,,'',,,,,,,;::;;;;;;,,,;:;:::ccclodddddo:cxxoOWWX0kl,,,,,:ookNMMMMWWWWWWWWMMMW0xONMMMMMM    //
//    MW0xxxxddoOXOO0l;,,'''''...''''''''.....';dKk;'',,;;;;,;;,,,,,,''',,,,,,;;;,;;;;;,,,,,;;;:cclllodooodxlcdxcdNWNWNk:,;:cclxKWWMMWWWWWWWWWMMMWKkONMMMMMM    //
//    MNOkOkkxxdOXOk0d:;,'''''''''''''''','''.';lOk:,,,;;,;;;;,,;,,,,,,,,,,,,,;;;,,;;,,;,,,,;;;:::clloddxxxkdcod:lKWNXWKo:lxOOkKWWWMWNNWWWWWWMMMMWXO0WMMMMMM    //
//    MX0OOOOOkxxKKkOdc:,;:,''''''''',,,;;;,,',:lkxc,,,,,;;;;;,,;;,,,,,,,;,,;;;;,,,;,,,,;;,,,,;;:::cllddddxkkool;dXWMNX0oo0NMMMWWWMMNKXWWWWWMMMMMWX0KWMMMMMM    //
//    WK0000000Ox0Xkdoc:col,,,,''''',,;;::;;,,;codl:;,,;;;;;;;,,;;,,,,,,,,,,;;;,,,;;;;;,;,,,;;;;;;:cllodddkOkollxXWWMMN00NMMMWWWWWMWKKWMMMMMMMMMMWXKNMMMMMMM    //
//    N00XKK00KKOOK0klldOkc;;,,,,,,,;;;:::::;;:clddl:;;;;;;;;;;;;;;;;;;;;;;;,;;;;;;;;;,;;;;;;;;;;;::clodxkkOkolxXMWNWMMWWMMMWNWMMMMWXNMMMMMMMMMMMWKKNMMMMMMM    //
//    N00XXKKKXXXKKX0dkNXkl:;;,,,,;;;;;:::::::cloxkl:::ccc:;;:;;;;;;;;;;;;;;;;;;;;;;:;;;;;;;;;;;;;::clodkOkOOolkNMMNNWMMMMMMWWWMMMMWNWMMMMMMMMMMMWXXWMMMMMMM    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract HwlPnts is ERC721Creator {
    constructor() ERC721Creator("DJ Pants & Joe Howl", "HwlPnts") {}
}