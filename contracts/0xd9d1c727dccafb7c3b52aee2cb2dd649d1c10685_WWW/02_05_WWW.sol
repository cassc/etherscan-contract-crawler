// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: A Whitewashed World - Open Edition
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    XXX00KXXXXXXXXXNWNXNWNNNNXXNNNNNNNNNNXXXXKKXXXNNXXNXXK00KNNXXXXXNNXXXXK0XXKKKXXXXXXXXXXXKKNXOkOO000OkKXXXXXXXXNNXXXXXXK0OkkOO0KKKK0OO0KXKKKKKKKKKK0000    //
//    kkxxO0K0KXXKKKXNX00XXNNNXKKXXXNNNXKKKK00K0KK0KXXKKKK0Okk0K000000KKKKKKK0OKK00000KKK0KKK0OKKOxxkkOOxdx000K0OOkk0kdxkkkocllc:,;xKKKKKKKKKXXXK0000KK00K0k    //
//    ..  .',,clcdk00OkkO00KXXK00KKXXKK000O0000KK0OOKKK00OOkkkkkxxkkxxkkxk0kxxxkkxxxkkOkxdkkddk0kollolllccodlllc;;:loc,:ll;'',;,,':OKKKKKXXKKKXX00KK0KXKKX0O    //
//    .  .......;lxkxolcdKXXNNKKKKXXNXKKXKKXK0KK0Ok0XXXXKKXXXXKK000K0000KXXKOOOO0OO0K00K0O000KKOxddxkxdxxkkkxddddxdxkddxxlcdlc;',;lO0KKXXXXKKKXXK0000KXXXXKO    //
//    '........';cc::,.'dKK00KXXXXNXKKXXKKK0OxkOOO0XXXXXKKKKKXXKKKXXNNXKKKKXXNXNNXXXXXNWWNXXXXKOOOOKKKK00KKKXKO0KXXXXXKK0xxkdllc;;oO0KXNNNXKKKXX000KXKKXNKK0    //
//    d:.......'....;:,;ldxO0KXXXX0Odokkdllc;.,oOKKKKKK0OkdooO000K0K0kx0X0OKXNNXKKK0OXNNXXXXXXK000OOKKKKKXNNNXXXNXXXKKXXK0Oxo::lc;oO0XNNNNK0KKXKKKXXXKKNNKK0    //
//    dl;,,,'.......coooc;oO0KKOxkkc..;;.. ....'xK0KKK0Ox:...ckkk0K0OkOKK0000XXKKXKO0KNNK0KKXXXK00kkKKKKKXNNNKKKXXKKKXX0O0K0d:col:d0KXNXNNXXXKXXXXXKKXXNXKK0    //
//    llol;.......',cocc::dOOkdc;;;'.'.....',,;:ldooxxxo:. ...'',loldO0O0K0O000kxkOO0XXX000KKXXKKKkxO00KXXNNXXXNNNXXXXXKKKXXOoll::x0KNNXXXXXXXXXKXXKKXXXK000    //
//    cdxc'.......,::,'..:ool;;:'';::c;',:c::odl:;,;::;'....''..,,'.,:ldxO00KK0OOO00Ok0XKKKKKXXKXKkdk0K0OKXNNNNXNNNNNNXXXKK0Okdl::xKXXXKKXKKKKKXXXXKKXXXKKKK    //
//    dkx:.........''.':llcc:';lcoollddodddooxxdlllll:,....';:;;;,,;;;;;lkKK0KKXXXKK0O00KXKO0OOKOOOOOKK0OOOKNNK0KK0KXKXKK000OOOd:cOXXNXXXXXK0KXXNXXKKXXK0KXK    //
//    OOo;...'.....'',cllc:::;'cO0kxxOKKOxdxddxdlldxoc;;,,,;cldocccclc::cok0000KKK0kkOOOOOkxdlcc:okOkO000OOKXNKOkkdxOKXXKK0OkxOxcl0XXXXXNNNXKKNWNXXXKKKKKXXK    //
//    0kl;'........',;clcc;:cc;cOKOOOKK0kdddkxkkdodkxdl:cllcokxollllollloolodddxdddoldxoclddl:,..:dxxO0000OKXK000xodk0KXK0K0xxkkccOKKKXXXXXKKXNNXXXX00KKKXNK    //
//    xolc,.........,cloc::cllxO000KKOkOOl;lxxO00kkxxxl;codddolc::;:lllloddolllloxxxxxdooxOkdl:,;lolldxxOKK0K0KXKOxxkxxOOOK0kxkxlckKKKNNXXXK0KXXXXXK0000KXNX    //
//    xodo;.........':lxoccc:ckOkxk0Oxdxd,':llk0kkOkxl;,:oxxoodl:;:::cloodxkkxdodxoldxxxkxxxdl:,;cccodddxxk0KKKK0kocldkOOOOkdxxd:;x0KNNNXXXKKKKKXXXXXKKXNNNX    //
//    ddo:,''''..''',:ldxxdooxkkkxxdoc:dd:cdxkkddkkkoc:coxxkkkdooccc::oddxxxdoodlc:ldxkOkdoddo:;;;:cldOkkdclkOOxc;,,;;lollodldkc''oKXXKKXNNXXX0KXWWNNNNNNXKK    //
//    oc;;,,,,,,,,,,;clddddooxkkOOxool;cxkOO00Oxxxxxdooloxxxdoc::;;:clolooodocloc::oOOkxxxdllddlcclc:lkxdlloddlc:,..',::,',;',;,''lKXKKXNNNXXXXNWWNXXXXNXK00    //
//    dc:c:;;;;;;::;:ccllldxxkkO00OxoododkOxdO00Okkdloddxdool:;;;;:coolodooolclddxxxO0kxdlc::clooddlclxkdooxxl;,;;'''';l;','.'''',oKXXNNNXXXNWXKXNXXXXXNX000    //
//    lccc:;;:ccc::::::llcdkxkOkOOxdodlcldkxxkxxkdoolllooc:cc::cccclollddllooldkkxdodxxdc:::;;;:lollllclddool::::,,,'';lc,..'c,',,o0XXXXKKXNNNK0KXXKKKKK000K    //
//    lolc;,;:c:;;;;;,,cooddloolc;,,,;cccoO0Oxddl:cool:;::,,,,;clloolloolcllodxkdooloxxdl:;;:::loolllccllllclc:;,,,,;::::;'.,l;'',dKXXXXXXNNNNKKXXXXNXK0KKXN    //
//    llc;,',;;,,,,,,,,:ooc;;::,'.....,;;cdl;,,,,,;cc;'',',:;;:cllllc:coolodddxxxdxxdddoc:;;;:lolcccllllcccooc,'',,;::::;;,..,,,,,dXNNXX0OKXXXKKXXXXKKKKKKXX    //
//    ol:;,,,,'''''',,,;coccc:;,.........';,....'',,'....',;;,;:cool:;cooloddoddxkkOkddl:;;;::clooolllllc:clc;'.',,;;::ccc:,'''.''l0X0Okl:oO00kloxxxkOKKKKKX    //
//    olc;;;,,,'...',,'',;;;;;;,'.......''''......''''...','',,;cool:;:cc::coddooooooddol::clooollodoolc:::;,'''',,,;clllcc;:c;...,k0kdc;;lkkdc;:c:;;;oxx0K0    //
//    oolc::;,,''..''''''''.';;,'......''''........',,,'',,'',;ccclc:::c:::coxdlcccccoollccloxxxdddddolc;;,,,;,,;,''',::;;,':l:....ldc:::ldkkdlodolc,';:cddc    //
//    oolol:;,'.',,,'...','.',,'''.....''''........';;;;;;,,:::;:cc;;:ccc:cldxxxddl:;clcc:::cooooodoollc,',,;:;;,'...''''.. .'.... .;,;:;:okOkoodoo:,;;;;;,'    //
//    lllol:,'...'''''..',''..'';;'............'.',,:::::;:llccldolccccclooddoolcccccclolcc:;;cclllllllc;;,','''.......''.   .. .. .,,:;,:lx0Oxllcclc;;c;'''    //
//    lool:;;,'.....'',,::,'.'',;,...','.........',;:;,,;;:odxoccloolcllddol:;;cclclllool::lllloolllllc::;,'.......''.''..  .''... .;;;,,ldxkkxool::c:;;,'''    //
//    loolc:,,,'....':llc;','...''',,''''.......'',;,,,,,,,:ldkdlodoooccloc;,,;odoolllllcclodxkxdoolc:::,''''.''.......     'oc... .:;:::lxxdxxool::coc:,,'.    //
//    lollc:;,,,..''';:,'......';:::;............''...'',',,;clldxddollodxl;',collooc::loddddxkkxolc:;;;,'''.........       .c:... .::cccldkOOxlc::;;;;;,'''    //
//    do:;:;,'....'';,''',,'...',;,,'...................'',;,,,:ccldoloddddc;;:cccc:;:clddddodkxdo:;,,,'...............      .......,;:odxddO0kl,..,;,'.',,,    //
//    ol;,,'......',,'''',,.',,'..'..''''................',;;,::,;cclool:;c::;;::c:;;cllloxkkkxoc:;,,,'.................     .......',:dkdclool;'...,c:,',,'    //
//    lc:;'.....'''''',,'............'''................';:llccc;cxxool;..,;;;;::;,,;cllccldxdc:;,,;;;'.......'''.......    .:,.'...'''cdo:;:;;;'''',ll,,,,'    //
//    ll:,....,,,,,..';c;'......'''.'''......',;,'......,cccodlloxOOdlc'...,:cloolc:coollooool:;,,,::;'.......'.........    'dc....',',cooollc:;....,c;',,'.    //
//    '......,::,,'.';llc,......''.'''......';:;,.......,;,,:ccldxxdl:;'...'clokxdl::lxxdooooc:;;:cc;,'......''.........    .,'...,c;',lxdoooc,.  ..',,'''''    //
//    ....',:cc;,,,,;:cc,...'.......','.....''........,;;,,:c:cdxdxdl::,..;;;cddc;;,,,coooolc;;;;::;'...................     ...'.';',;llccll;.  .,'''''..,,    //
//    .'.',,:c;,;,';c::,..',;;,,,'..','.........'',;,';:,'.,::lxdllddlc;.'::,;cl:;,'..;cclc:;,,'''..'...................    .;;','..,:cccll:,'...'..''..',,,    //
//    '''..';:;;;'.,c:,'',,,,;;;;'.',,'.''..''''',,'''''.';:looxoldkxc;,';cl:;;;;::,',:cc:;,,,..........................    'dc''...cc;;:llc;;;,;:,,,'......    //
//    ,''....'',,'..',',;;;,,;:c;'',,'',;,'.....'''.....',,,cddllxOdl:,,,:llccc:;;;,',:::::,,,...........................   .c;''..'c;,,::;;;::,,::,,'...','    //
//    ,,,.....'''''.......'',:cc:;''....','..............''''cdolodoc;'..,clc::;''.''''''',,,,'...'..''..................    .'''..,:;;coc'..''.';,,,'..''..    //
//    .''.....''........  ..,;:c:,''..............'......',,,:lllc;::;,..',,,',,,''''.......''''.',,,,'.................     .....':l:;:ll:''''..,,';,',,...    //
//    .......'::;,,,'..  ..;cloc,''..........,,''........',;:clcc::;,,'......',,''''''.......'',',;;,'................      .......;;..,;c;',,'';,....',.. .    //
//    ..'''.';;;,,;,'....';c:;:lc:,'........',,'.........',,,;;;;;;,.........',,''''''......'''''''''..............      ......''.....,,,::;,,........'.....    //
//    ;;'..''......'..''...,:c:::,',''''.................'.................'.''''''..........',,,'...'...........      .......'.....':;.','.'...............    //
//    ,'..,'................,clc:;;:;,''........... .........................'.................''...............     .''...........',;.............  ......     //
//    ...''..'...............';::,;;cc;,'','..','.... ......'....  .........''..............................       .,;,..';,,................  ...   .......    //
//    ..,,,',,.............',',clc:,''''''''..... .........................................................      .,;;,,;lxdl:'............ .         ......     //
//    ;:;,''............,:ccc:;;,....''......'......................''....................................     .';;,,;lx0Ol;,............             ....      //
//    ,,'...............,cl:;'....  ................   ..............''..................................    .';,;:clodooc'...... .. ...              ...''.    //
//    ...     ......... 'cc,....... .  .....................   ........................................    ..,;;;cokOxc;;;......                     ....',.    //
//    ..     ............''.. ....     ........... .........        .............................. ..    ..''',,cdxxd:'',,....                      ........    //
//    .      .. ....',;;,.......         .     ..........  .......................................      .....,ldxxo:,..''....   ...        ...     ..  .....    //
//    ...       ....:c;,'.....          ..   ..........       ......    ........................      .''.'':dOkxo:;;.','...... .....       .   ......     .    //
//    ...         ..;,.                .. ............  .              .....................       ..',;;,'..:kd:,,'......'.........    ...     ........   .    //
//        .      ...'.              ..      .. .......  .   ....    ......................        .',,;:cc'..,lc,...................    ....................    //
//       ..     ..'..                ..                    ....     .  ............ .. ...       ....,:oxd;..'''......  .........       ...........  .......    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract WWW is ERC1155Creator {
    constructor() ERC1155Creator() {}
}