// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Donald Silverstein Hendrix Puzzle
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNK0OOOOO0KNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKkdlccllc:;:ld0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOdoollllllc:::;:oKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKxdoooooollcc:::;,;c0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNkolcllllc:::;;;;;,,;oXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXxolllc:::;;,',,,,,'':0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWNXOoclc::;,,,,'',,,,,'.;xKXNNWMMMMMMMMMMMMMMMMMMMMMMMMW0od0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKXNMMMMMMMMMMMMMMMMMMMMWWWNXXKOxxdollccc::;,,,,,,,;,,''..',;:cloxk0XNWMMMMMMMMMMMMMMMMNk;..,ckKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWK0OOOOKNMMMMMMMMMMMMMMWWNXK00Okxxxdoolccc:::;;,'''',,,,,''''.'',''''''';:ldk0XWMMMMMMMMMMNd,......;oONWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKkl::coxOO0XWMMMMMMMMWWNX00Okkkkxxxxxxdolc::::;;,'''''''''.....'...''''''.''..',;ldOKWMMMMWKo,.........':d0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNOc'..,;,,cxkkkKWMMMMWNXK0OOkkOOOOkxxddxxdolc:,,,;,,'''.''''........''.'''''''''......';cdOXN0c'.............'cxXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKkl,....',,'':ooclxKXXK0OOOOOOkkxxxxxdodxdolcc:;,',,,,,'''.''.........'''''''''''...........':c;.................:OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOl:;;,',''....',,',;::oddxkkOOkxxddddoldxolc:;:;,,,,'',,,,,''........'.....''''...............................,lkXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOdc'',,''............;:cokOxdxddoollloollc;;;,,,,,''''..''......''''...'''''......''''....................;dKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKd;'''''''..........',:lollodxxoc:cc::::;,,''''.''''........'''''''...''.........'...................'ckXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXkl;'',,,'...........'',,,:lxdc;;;;,,,,,''''...'''........''...'...................................:0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0c'..',,'....'...........'::,''''''''','''.....'.......''........................................':dKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXkc,'..';:;,''..............'...........''''.........................................................';xXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNk:'.','',:llcc;.............'',,...'...............................................................''''''ckNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKl'...,;;,',:ccl:'............',;;'.......................................'........................''.',''..'l0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx,....'''.....',,'..........'',,,,,'......................'.................'''''''''...................'','...;xNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKl............................''',,'.......................................................................'''''..,oKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO;.  .............................','...............................................................................'c0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk,. .....''........................''................................'''''.............................................;kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx'......',,''.................   ...'.............................'',,,,''''.....................''..........'...........'xNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx'..................''........... ..............................'',;;;;;,''''....................'',,'........''...........,kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO;....'..............','.........  ........... ...........'...'',;;;:::;;,,,,,'....'''','............',,'......'.............,kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0c'...',,'...........',,,.....     ........     .....'''....'',;;;;:cc::::::;,,'...',,;;,''.............''.....''..............,OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXdc;'''',;;'............,'....    ....... ...    .....'',....',;;;:ccccclllcc:;,''..',,,,'''.........''..''...''.................:KMMMMMWNNNWMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMWNNWMMMMMNxcc::;'..,,.................................... .............',::::ccclddodol:;;,''''.............'.....','.......................lOOkxol:;cKMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMWklodddxOKkc;:cc:,..........................',;;:;;;;,,,'.....''........',;;;:clodddxxdoc:;;,,,'''..........''....';,.........................'........xWMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMXd::;,'',;:;:ccl:,'........................';:cclcclccc::,'.............',;::clodxkkxxxocc:;;;;,,'....''....''''''''.................''................lNMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMM0l::,'....':ccc:,''.......................',:clllllllllcc:;'............',:lllodkOOOkkkxdoc:::;,,''''.......'..........................................:KMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMWOc;,......';;,,,''.................'......';:lloooooollcc:;'...........',:cllodkOOOOOOOOOxc:c:;,'......'...............................................;OMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMNd,..........'.............................,:cloodooooolll:;'...........,:cclodxkkOOOO0000Ooclc::;,....''................................................dWMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMKc..............'''''......  .   .........';cloddddooooooll:;'.''......';clloddxkkkxkkO0KKKOolc::;,''''''................................................cXMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMWO:...........'',;:::,....................,;clodddddddddddoolc;'''......,:clllloool:::codxkO0Okdlc:;;;;,'''........................................','....;0MMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMWOc:::::c:,..............................,:coodxxxxxkkxxxddool:,'......';::;;,,,,,,,,:clodxkkkkxxxdolc:;,'''......................................,kXKK00OOXMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMWNXXXXXNNk:'..      ...................',:coodxxxxxkkkxxdlllcc:;'.......,;,'.....';codxxkOOOkkxxxxxdolc:;,,,''...........................''.......,OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMk'.'........  ...........',,,;:cloddxxxxxxxxdol:;,,,;,,,,'....',,,''''',:oxkkkOOOOOkkkkxdddddoll:;;,''..........................'........,kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO:;,,''...... ........'';:ccllloodddxxdddooolc:;,'.....,:;,'...',,,,,,,,:odxxxxxxxkkxxdddxkkkkxdolc:,'''.................................,kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0lc:;::;;'...........',:ldddxxddddddoolcc::;;;,,,'.....,c:;;'...',,;;;;;;:looddxxdolodxkO00000Okxdlc:;'......................'''.........,kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKdcclllcc:::;,'''.'',;cldxkkkkxxddool:;;,,,,''''''.....;;,;::,....;coooolclooolc:;:cdk0KKKKKKK0Okxdoc:,..................................,kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXdlddollllolcc::::;;:clodkkkkkkxxdol:;,''....'.....''';lc,'''''...;oxkkkkdl:,,',;:coxO0KKKKKKKK0Okkxoc;,.................................;0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXdcllllooddocc:ccc:::coodxkkkkkxxdolc:;,,,,,,,......';okdl:,'..'.'cxO0000kdl:,,;:cok0KKKXXXXKKK0OOkkdoc;,.................'''............lXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx;:llooddlcc:ccccccclodxkkkkkkkxxdollllccc:,'......':dkkxdc,,,;;:dO000K00Okdlcldk00KKXXXXXXK0000OOkxol:;'..................'............dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0c:lloddollccccccccllodkkOOOOOkkkxxdxxdolc:,.......,;okkkxo::::cok00KKKKK0OkkkOO00KKKKXXKKK000OOkkxdoc:;,'.............................'kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNxlodddddoolccccccclodxkkOOOOOOOOkkkkkxxoc;,.....',;:cdkkxdl:;:ok0KKKKKKK00OO000KKKKXKKKKK00OOkkxddolc:;;,,'''.........................:KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKxxxxxddoolccccccclodxkOOO000000OOOOkkxddl:,'',;;:clloxkxxdlcokO0KKKKKKK0OOOO000KKKXXKKK00OOkxxdoolllccc:::;;,,,''''''.............. .dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0kkxxxxdlc::::::clooxkOO0000K0000OOOkkxxdlc:;:ccloodddxkkxddk0KKKKKKKKK0OkkkOO00KKKK0000Okkxxddooolllllllccc::;;;,,,'''.............:KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXOOOOOkoc:;;;;;;:cloxkO000K000000OOOkkkxxdolccclodxxxxdxkkkkO0KKK0KKXXK0OkkkkkOOOO00OOOOkkxxddddoooooooooollllcc::;;,,'''..........'xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKOO00Oxdlcccc::coodxOO00KK000000OOOOkOkkxdoc:coddxkkkxxxkkO0000KKXXXK0OxdxOkxxxxxxxxxxxxxdooodddooddooodooddoolccc::;,,,''........oXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0O0000OkkkkxxxxkkkOO00KK0000000OOOOOOkkxdoccokkkkkkkkxddkOOOOOOkkkxddollx00Okxdddoddddooolloodddddddddddddddooollcc::;;,,''.....cKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0000OOOOOOOOOOOOO000000000000OOOOOOOkxdol:;lxkxdodxxkxoodddl:,'...',;lxO0000Okxddddddooollooddddddddddddddddooollcc::;,,''....:0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWN00OOOOkkOOOOOO000000000000OOOOOkkkkxdol:,.,;;'..,coddollc:;,'''';coxO0000KKK00Okkkkxddollloodddddddddxxxddddooollc:;;,,''...'oKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0OOOOkOOOOOOO00000000000OOOkkkkkxxolc;,'.''.....':cclxkxxdxxdlodkO000000000000OOOkkxddoooodoooddddxxxddddddooollc:;,,,''..'',cdOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNX0OOOkOOOOOOOOOO000OOOOOOkkkxxxxddol:;,'.';;,'';:ccloxkOOOOOkolodxxkkxxddodddxxkkkkkxxxdddddddddddxxdddddddooollc::;,,''..'',,;;:cdOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNK0OOOOOOkkOOkkOOOOOOOOOOOOOkkxxddddolc:;'...';;,;lxkkkkOOOOOOOko:::cllooddolcc:::cloodxxxxdddxxxxxxxxdddddddddollcc::;,,''...',;;:::;;;cokKNMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNK0OkkkkkkOkkkkkkkkkkkOkkkkkkkkkxxdddollc:;'...',,,,:dOOOkOOOOOOOkxc:clllccccllc:;,,;clllodxxddddxxxxxxdddddddddoolcc:;;,,''....',;:::::::::;;cOWMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKOkkkkkkkkkkkkkxxkkkkkkkxxxkkxxxxdoooolcc:;'...'',,,,ckOOOOkOOOOOkkxlcccllc:cccccclodxOkxoodddddddxxxdddddddddooolc::;;,'''.....',;;::ccccc:::lkNMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNKOkkkkkxxxxxxxxxxxxxxxxxxxxxxdddooollcc:;,......''',lkOOkkkkkkkkkkkxddolc:;,:coxkOO000Okxoodddddddddddddoodddoolc:;,'''.....;do;;::ccllccccldKWMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0Okkkxxxdddddxxddddxdddddddooooolcc::;,'.......,coxkkkkkkkkkkkkkkkkkkxo::cdxkkkO00OOOkxdddddddddddddddodddoolc;,''......,oKWNOoccllllllloONMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNKOkkxxxdddx0XKkdddddooooooolllc::;;;,'...'''''cxkkkkkkkkkkkkkkkkkkkkkxdddxxxkkkkkkkkxxdooooddddddddddoooolc:;''......'cONMMMMNOoloooookXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOkxxxxxOXWMMN0xoooooooollccc::;;,,''.''',,,':dkkkkkkkkkkkkkkkkkkkkkxdooooddddooddddooooodddddddddooollc:;''.......:xXMMMMMMMWXkdoox0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0kxxOKWMMMMMMN0xollllllcc:::;;;,,'''',,,'';lxkkkkkkkkkkkkkkkkkkkkxxdlc:;;;:::ccclllloodddxxxxxdooolc:,,'.......;xXWMMMMMMMMMMWKkOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0KNMMMMMMMMMMN0xolllcc:::;;;;,,,;;,,'',cdkkkkkkkkkkkkkkkkkkkxxxxxxxoc;'''',;::cclooddddxxxxddolc:;,'......':xXWMMMMMMMMMMMMMMWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMMMMMMMMMMMMMN0xlccc::;;;;;;;:::;,'':dkkkkkkkkkkkkkkkxxxxxxxxxxxxxxdol:::coodxxxxxxxx                                                                              //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SLV is ERC721Creator {
    constructor() ERC721Creator("Donald Silverstein Hendrix Puzzle", "SLV") {}
}