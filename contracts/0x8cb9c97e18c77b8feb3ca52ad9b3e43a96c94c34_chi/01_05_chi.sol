// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: groovychi
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                      //
//                                                                                                                      //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMWXKKXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXK0OOOKNWMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMN0xolc:cldkKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOxoolloooodkKWMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMNOdooooolc::;:lkKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXkoccclloodxxxxdokNMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMWKxoxxddoolc:::;;;:ldk0KXNWMWWNX0OkkkkOOkkkkkOO0XNWMMWNKx:,;cllllloddxkkkdodKWMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMW0ooxxxdoollcc:::::;;;;;;;:ldddolcccccccllllccccclloodoc;',;::ccccloooddxxxxod0WMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMWOloxxxddooolc::::::;;,''',;:looddddxxxxxxdxxdxddddolcc:;,',;;:::::clooooodxxxdd0WMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMWOllodxdddddolll;',;,,'.',;coddxxxxxxxkkkxxxxxxxxxddddoc;:c:;,,,,,cxkkdcclloddxxdokNMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMNOooodddddddookXNKl,,'',::'.':dxxdddddxxxxxxxxxxxxxdddo:...,ldoc;:kNMMMNxc:clooodddod0WMMMMMMMMMMMM    //
//    MMMMMMMMMN0dooddxdddddod0WMMMNx;;cll:...;odoooodddddxxxxxxxxddooooc'..'coddoo0WMMMMWk::clllodddllkXWMMMMMMMMMM    //
//    MMMMMMWKko::cclodxddddoOWMMMMNxlooc;,'',,;clllloddddxxxxxxddollc:;;;,'.':odxdd0WMMMMWx;;:lloddoc::cdkKWMMMMMMM    //
//    MMMMNOoc;;;:cloxxdodxddXMMMMNxcodl;,;;;;,,,,:lloodddddddddddoc;'',;;;,'..,cdxodXMMMMMXl,;clolllcc:clloxKWMMMMM    //
//    MMMNxc:;;coddxO0OxocoddKMMMM0c::,..''',,,,,,,;loooddddddddddo;.''''''....,cddddKMMMMMNo,;;:cllcoxdl:coooONMMMM    //
//    MMMOc:;;cooolodddddccod0MMMMk:c:;'....',,,'';,,loooddooodooo:'''';:cc;',:ldxxxo0MMMMM0c;;:oxxdodkxool:looOWMMM    //
//    MMWk:;';lol:lklcdddl:ookWMMMO:cldl'.';cllccdx,.:oooooooooooc.'cc:clcccooldxxxdoKMMMMWx:;:okxxooxoodddl:ookWMMM    //
//    MMMKl:;,clollllododl:ookWMMMKl:lddccddxkkOK0o;;;c::c:ccc:cc:,,ck0K0OO00dldxxxoxNMMMMNd:::dkxdldkloddxo:ooxNMMM    //
//    MMMWOlc::oxdoodoool:coo0MMMMWOccodolxKNNWW0o:;;;;;;;;:::;;::;::cxKNNNXxldxxxooKMMMMMWkll:lxxodxooddddccdoOWMMM    //
//    MMMMWOoccccccclc:;;::lOWMMMMMWOlcldoloxOko:;:::;;:::::::::cccclc::lddlcldxddoOWMMMMMMXdllccox00kdddl:;:lkNMMMM    //
//    MMMMMMN0xlc:c:;;;;::o0WMMMMMMMWKdcllc;,,;;:cclllcc:::;:::::lddooc:;;;:lodddoOWMMMMMMMMNkolllodxdlc:;;:o0WMMMMM    //
//    MMMMMMMMWX0kkxdddxk0NMMMMMMMMMMMNOocccc:cclloooolc:ccccccclodddddoooodxxddxKWMMMMMMMMMMWXOxdooolc:cod0NMMMMMMM    //
//    MMMMMMMMMMMMMMWWWMMMMMMMMMMMMMMMMMN0dlcloodddddddddddddddddddddxxxxxdoodkKNMMMMMMMMMMMMMMMWNXXXK0KXWMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOxocclooooddddddddddddddoolc:;,':OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNOd:'''',,,;:cc:::ccc:::;,,'.....';xXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOo:,'.........';:::::cc:;,''....''',,,:o0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx'..'''.........,;;;;::clc,....',;:;,,,,,c0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO;....',,''''...,;;;;:::loo:,'';::cllc::;,,dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKc,''.',;;,;;;,..,;;;;;;,;clc:::ccc:cloolc;,:OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx,,;;;;;;,',;;,'';;;;;;,,'',,;:cc::::cllll:,',kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx'..';;;;;,'',,,,,;,,''''''',,,;:cccc::cllc;...lXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK:....,;::;'.',,,,,..............,:clc,,:cc;'.',;oXMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx,'..',;;,'...','.................;cc;..'cc:;;;;;cKMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMKc..';;;;,'........................,;;,..':cccc:;;cOWMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMNo'...,;;,'... .....................'.....':cccc:;;;l0MMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMXo,'...;;'.............................','..:cccc:;;;;dNMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMk,''',;;;;''''.......................,;;;'..;cccc::;;':0MMMMMMMMWOldKWMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMKc'',;;;;;;;;,'......................,;;;,'..':cccc:;'..lKMMMMMMMWd..;OWMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMNd,'',;;,,,,;;,.....................',;;,,''...;cccc;'..';oXMMMMMMMO,..cXMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMXx;''',,'''',;,....................',,;;,,''....';:c:;'.';,;kWMMMMMMK:..'odllokXMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMWx:;;,'''.'''''...................',,,'',,,'......';:::::ccc:lKMMMMMM0:...     .,OWMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMNd;:;,'...'''.......................'''..',,''.....,:c:::clllckWMMMMM0;...  ',.  cNMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMWOc::;;,...','............ .........';::;;;;;,'.....,:c;..':olcl0WMMMMO,..   ',. .oWMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMNkc:::;;,...''............  ...'',;;:::;;;:::;,.......,,',;:lll:,:OWMMMk'....   .'oXMMMMM    //
//    MMMMMMMMMMMMMMMMMMMWKo,''....'...''..... ..... ...',;;::;,''',,;:::,''......,:llcc:,.';cOWMWx...:kxdxOXWMMMMMM    //
//    MMMMMMMMMMMMMMMMMWXxc,'''..........''.............,,'',,,,,,,,,,;::;;;,....':c::;,'',cl,;o0Xo...lNMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMN0kdc::cc:::;,,'...','......'''..'',,,'''''..',,,,;:::::;.....;:;,,..,:cc;,,:xc..'xWMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMWk:,',;cccccc:::,..';:,...''';;;;;:::;,',,,,,,,,,,,;::;;;'.....',..''',;;::;;,;'..;0MMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMOc,'..''',;::cc;..;c:;,',,;;;;:::::::;;;;;;;;,,,,,;;,'...... ....,,,,',;;,,;;;'..;0MMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMW0o:'.'''.',;::;,',,,;;;;;;;;;:::;;;;;;,,,,,;,,,,'''............',,;,,'...',;;;'.,0MMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMNOxl;o0Ol'',;;:;,;;,',,''',,,;,,',,;;;,,,,,,;;,'...''''.....''..,,''''',;;;;,...:KMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMM0cxNNx:dx:;:;,;:;;,..',,,'''...',;;;;,,,',,;,;:cccc:,'';:::'.,'.',;;;;;:oc...lNMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMKldNKloKW0dc;',;;,'',;:::;;:;:;,,,,,,,,,,::ccclooolc:;'',;,'',,;:ldo;cl:d:...dWMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMM0cxKxlOWMMW0c......,:cllolooccc:;;;;;;::cc:::::cloool:;,,'...;dOKNWNold:l:...xMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMWxcOKooKMMMMKl'...'',codddddolccc:;;:::ccccc:::::loool:;,..',,dNMMMMMOcdl;,..,OMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMXolK0cdXMMMMKl;;'',;:clddxdocccccc:;:::cccccccccccllll:,'',:;:OWMMMMMKldx,...,OMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMXolKXOKWMMMMO;.,;:::clodddolccccc;,',;::cc:;:::ccccloolc::;;;lKMMMMMMNoo0o...;KMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMWOd0MMMMMMMWx,',:ccclodddoc::::;,..'',::::::cccclooddddooc,';cOWMMMMMXodXx...:XMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMWNWMMMMMMWk:,;::::ccoddddl::::;,;;,';:::::cccccodddxxddlc;;::oKMMMMXkxKNo...cNMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMK:',;;:ccccloddoolccllcc:,',::ccc:;;;;coddddoc;,,',,:kWMMMWNWMNl...lNMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMM0:.',;:;;;:ldddl:::::cc:;,',:ccccc;;;:lodddolccc:;;:ckWMMMMMMMX:...dWMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMXl'',;::;;:cooddocccccc:,'..',,;:llooddxxdlcc:cllcc:::c0WMMMMMMK:..'kMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMWk,..',:::::::ccllcccccc::;;'...,:cllollodo:;,,;cc:;;;;:kWMMMMMM0;..,OMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMXl,,,,,;::;,;::::;::c::;:;;;,',,::::;,,';ldoolcccc:::;;;oXMMMMMMk,..,OMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMWO;',;::;;;,,;:;,,,;::;,clc:,..',;:c:c::;;:cllccc::;,''',c0MMMMMWx'..,dkxk0XWMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMXo,'';cllc:;;::cllllolcloolc:,'.';;,,;:;,',;:::;;:::;,;;::kWMMMMWx...     .'oXMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMM0lccccllll:;'',;clooooooooolc;'..,,'',,,;:clllllc:::::;:::dXMMMMWd...   .'.  lNMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMWkc;,',:cccc:;,'.,;clccccc:;;;;,..,;;cllolllllllc;,,;:ccllllkNMMMNl...  .,:.  :XMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMM0oc;,,;looodoooollloddddddlllcllc:;;:oxkkxdddooooolloddxxxdloKMMMXl....     .:0MMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMWOlc::codddoooodxxddxkkxdddlclllcc;;::cllllodoloddddlc:lddddldXMMMWd..,dxlccoONMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMWKOdoodxxkkxxxxxxxxxxxddddddxkxxdxxdoxxdddxOOOOOOOOOkxdxxxkOXWMMMMXxdONMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMWWNNNWWMMMMMWMMWNNXXXXXXXNWWWWMMWWWWNNNWWMMMMMMMMMMMWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                                      //
//                                                                                                                      //
//                                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract chi is ERC1155Creator {
    constructor() ERC1155Creator("groovychi", "chi") {}
}