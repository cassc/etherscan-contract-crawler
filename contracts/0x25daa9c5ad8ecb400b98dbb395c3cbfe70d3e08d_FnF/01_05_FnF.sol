// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NATURE
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    kkOOkkOOkkO0OkxdlooxkkxxkkkOO0KXXK0xddkkl:;;lx0K00KKK0Okkxxxxkxdoox0KKKKKXXNNNNNNNNNNXOdddddlcoOK0O00KNWNNNXKKKOxdoxO0XK0O0XX0Ox:,,;cxkxkOxooddxxkxox0    //
//    kkxddxxxddk0000kolodkOkdkOO00KKXNNXXXXXK0OOO00K0OkkO0kxxxdddddxxkOKXXXXXKKXNNNNNNNNNNX0kxdoolcoKNXXNNNNNNNNXXKOxdddxkOK0kkOOxllc;;clooooodlcldxk0OkkO0    //
//    dxddodxxddxkxxkdlllccdkdloxkkOO0KNNWWNNXKK00OOkxdoxkxxxooooodOXNNXXXXXXXKKNNNNNNNNNNNXK00OkkOO0XWWNNNNNNNNNXXKOdxO00Okko::cccc:cclooxdooooollodOKOO0Ok    //
//    dxxxdodxdddoooolclcclodxl:cdxkOOO0KXKKKK0Okkdddxddxxdooc:cdOXNNNNNXXXXXKKKKKKKKXNNNXXXXKKKKKXNNNNNXXXK00KXNXOOOdxkxdlccc:;:cloodkkdlodolol:,;ldk0KKOxO    //
//    odxkddolc:lddolccccccoxxdooooxkOOO00OkkkxddxdddxdddlllccokXNNNNNNNXNXXXKOOxxdollokOOkkkkOOO000KK0KKKOxdoxOOklodl:cc::cclc:lddxxOX0l:ccllc,',:cokKXKxoO    //
//    llllooc:::clllc::ccc::clxxlc:cokkdolooollllodxxdoooccllkKXNNXNNNNNNNNXXKOkkkOkxdodddxxodxxxddxkOOO0Okdlll:;;,,;;;;:cccccccdddxkOkc;cccc;,,,:ooox0KOkO0    //
//    llooddoodddooollloolc:;coxdc::;lo:;;:cllc::lodllloocok0XXXXXNNNNNNXXXXXXKKKKK000000kxdodkkkkOO00OOOOOxlc:,,,:c,';clolc;,:odddood:,;ccc;''';ldoodkdlkX0    //
//    olclolllodkxxddoddoddooddxxdlc:lo:;:;cl:cccllc:lloodkKXXXXXXXNNNNNXXXXXKOOOOOkxO00KK000OKKOOOOK0Okkxxdoolooc;',:cllccc;;lddolccl;;:cll;',;cooodol:lKXO    //
//    odl:c:;;;:c:::c:;;;cccc:::cloddooc;;;;:::::cccoddxxkk0KXNXXXXXXNNNNXXXKkocc::;cOKO0KKK0kkkxddoddolodolcccodc;:::;;;;oo:ldddoc:cc;,:cl:;';oxllodl,'xXXO    //
//    xdlcclcccccc::cc;;;;::::;,,;::clolcccccodlxkdlc:codxkOKXXXNXXXNNNNXXXKOxoolcllodxdodxxxooollcllllcllcclcll:,:c:;;,':occdxxoccll:coll:;,;o0Kxllc,.;OXKk    //
//    colcloooolccc;;::c;;::::;;;:cclolllllcdOOdddllodlccldxOOOKXXNXXNXKKKOkkddxxddddxkxooooodxkdccc:cccclllllc:;:::;;;;;ol;lxxxc;:dl:odl::c,,oOkxddd:.c0XK0    //
//    .'cdooddoddlccc:cc::cc::ccc:ccloll:;coxxkxxxdoddollccldxkOO000XXXK0OOkOkkOOkkkxdooolc:lOKOoccclc:clolclc;;:c::,;:loc;:oddl::odlkOdoooc:okxdxdk0l'lKXKO    //
//    ;'.oOxxxdddoccllcc:c::cloooooolcc;:ldxkkkkkxdddlcllllc::oxOO00K0O0000KK0OOxdlccc:ccc::dxoloolllccodolxko:;;:::;:odc:clooldddkk0XKkocccokOkOkk0K:.c0XK0    //
//    ''.cOkxxxddollol:ccclc:::ccodoc:;cxOO00KKK00Odooocc:llol:;lkOkOO00KKKK0kddlc:ckOdccc:oxook0xllclooccdkocl:;,,;coxo:odoooloxxdOXXOdl:;:d0KXKOxOOc,lOXK0    //
//    ...;dkxdxdxdooccloooc;;:clool:::o0KOOXNNXXXXXK0KKkocoxkko:;clloxO0KOxoc:clodk0Kklllclxkdlkklcdolloccxdcll;,,,o0kddkKOdoodOKdoKNXkddooxOKXKKKkOkoox0XK0    //
//    ...:dddddddolllloooc;,;:cloollcdOKKKXNXXXXXXXXXXXXK0kk0Kkdddo::o0Kkc,;:clok0KKkoll:lkkOkdd:;okdddxdl:cdxl;;;,dX0kOXX0Okk0XN0OXNNXKOdx0K00KKOkOxookKK0K    //
//    ..,lddddooolllollllc:;clooolclx0KKXXXNXXXNNNNNXNXXXXXXXXXXXKK0xoddc::ccclkKXKkollc:dOkkdol;lO0kdxkOo':oooc::ckX00000OOKXNNNNNNWNNNK0KNX000Oxk0Oxx0XXKK    //
//    ;llldxdooolcll:;:cccc:lxxdl:cOKKXXXXXNXXNNNNNNNNXXXXXXXXXXXXXKKXXOocoxxox000koclcclxxodxOkxKXK0xdkOl:llcc:dKKXK00kkkxkXXXXNNNNNNNXXXNNNX0dlokO0OO00Odo    //
//    ddollollc::c::;cc::;:ldkkxdx0XKKXXXXXXXXXNNNNNNNXXXXXXXXXXK0OKKKXKxoldkkO0OkdccldkkO000KKKXXK00OO0kodxdccoxO0X0xxxdxx0XNNNNNXXKOO0KOOXNKkook0Oxddoc:::    //
//    dlloollc:ldl;,,;ll:cldkkdk0KXXXXXXKKKXXXXXXXNXXXXXXXXKKXXXKOkkOk0XKOkkkdxxxxddodkKKXNNNXXXXXKK000OoxOOOxk0kdx0kdxkOOKXXXKKKOkxolcokdokxxxddxdlccclllll    //
//    olloc:::lxko;,;:lccldkxldKNXXXXXXKKKKKXXXXXXXXXXXXXXK0KXXXKOOOOOKXXKKKKOooxxkO0KXXXXXXNXXXXX000O0OxkOOkxxkkxOKkk0O000KXK000kkOOkkOOdcc::cccccccclcc:cc    //
//    cccc:cllxkoc;;clccldxxodKNNXXXXXKOOO0XXXXXXXXXXXXXXXXXXXXXXKKKKKKKKXKKXKOkxxk0KKXXXKKXNNXXXXXK0000kk00xxkxkxk0000KK0000KXXKOkxdooooool:ccccclllc:::;cl    //
//    clllxkkkkl:cc;clccodxdd0NNNXXXXKOdk0KXXXXXXXXXXXXXXKXXXXXXXXXXXK00KKKKKXXKOkkOKXXXXXNNNNXXXXXKK0Okk0KKK0OO0O0KK000kxolooodocc:::::coxxocc::col::cllcod    //
//    ccld0KOdc::cccodlloold0XNNNXXKK00000KXXXXXXXXXXXXXX0KKXXXXNXXXXKK0OKXKKXXX0OdoOKXXXXNNNNNXXXK000OkkOO00Okxooooc:llccclodooollccllllllc:c:cllo::looollo    //
//    coxOKOl;:lodxxxxolccokXNNNXKK00KK000OKXXXXK00OOKXXK00000KXXNXXXXXkoONXXXXXKOdclxO00OOOOOkkxooddoolcclollc;,,,.;loodkOOkxdddddoocclool:;,';ccoc,:ccllcl    //
//    okxxo:;:clodkkddlcc:o0XXXXXK000K0O0OkOKKK0OxO0kkKXKKOk000KKKKKKXKOOKXXKKXKOkkdc;,,'..'''''''''',,;;:::::::;clox000KXXXKOxxxxxdolccc:clc;,',:ld;,:ccllo    //
//    ddollccccccldxooolccdKXKKXKKKKK0kxO0kxk0OOxokX0xOKKXKO0KKOO00kOKKKXXXXK000O000k:......''',,;;::::cccccccc:cldk0KKXXXXXXX0K0OOddolodddooolc:;;ll;:c:cll    //
//    oc:lllccc::cldollc:cx0XK0000KXX0kk0KOdxOO0kxOXKOOOKNN00K0OOKKOk00OKXXXK000KXK0Od;.'''',,,::::::ccclllllcccokO00KXXNNNXXKKKK0koddoodddddddxdlccc::;;;:c    //
//    ;;;:loolccoooocclc:d000K00Ok0XXX0OKXKOkOOOOxkKXXOk0XKO00OOOKXK00K0O000KK00KXK0Oko,'',,;;;;;::ccccclcclc::lkO0KKXXNNNNXXK0KK0OkOkxoodoolc:::::c::c:;:co    //
//    ';::oolc:clodllllccxKKKKXXX00XXX0k0K0OkO000kloxdlccc;,;;::;:lolldOkkOOKXKKKKXXKkd:',,;;;:::lc:;;::cclc:;cxO0XXXNNXXXXXXKOkkxxocc::::clcc:cllcc:cllc::c    //
//    :llllccccloxxoollclkKKKXXXXXK0KXKO0XKOkdlcc:,,;::::cll,,oxc:clc:clcccccloddxOXX0do;',:;:c::ccc::::clc:;:dO0KXNNNNXXXNNKkkOxl;,,,,;:coxxxkxdoooooc:;;c:    //
//    oollolclloooddoll::kXXKKKXXXKOKXK0OOxo:'''.',,;cloodO0l;oOOocoolc:clc:'';:clldOOxdl,';::cc;,:ccllcc:;;,l0KXXNNNNNNXXXXOxdool::,;cccldOOkxxddlcl:,',:lc    //
//    ooodddddodddxdolc:;oKXXXXXXXX0O00koc:;,,;;''.,:loxkOKKdcoO00kdxdllolllc::cldoc,:dkdc,,;;::;;;:cllc;,,':d0XNNNNNNNXXKK0xl::ll:;:okkkxOKKOkxlc:::;;::cox    //
//    ddooddddodxdddolcl::kXNNXXXXN0ollc,;ol;;,''..,:cdO00KKdoOO0KKOddkkkxdoccc;;:cdl':kxl;;;:;;:lc:cc:;,,,:d0KXNNNNNNX0Okkxlc;:c::cdKXKKXX0kdlcclcc:;:clclx    //
//    xdooodxoodooxxdxxdl;oXNNXXNXX0o,..,dxol;,;'',:lok0KKKKdoOKK0OOxodOKKK0xc;:cccod;:kxl,'',;;coccc::,,,;lx0KXNNNNNXOdxkkxdc:llldOKKKKKK0xddc;:cc:;:ccccdk    //
//    oodxxxdlodddxxxool:,lXWWNNNKxl:,':okxxl::;,,;lxOKKKKK0dlxKX0xkOkdoxOOOOdllcccll:lxdc'..,,;cc:;;::;;,:ok0KXXXXXXOdokOxdxlldk0KKOkkxxdodoccc;,;;,:lc:ck0    //
//    loodxkxlcooloollcc:';OWWNXOo:,''cxOOOxodc,,';oOXXXXXK0lcdxO0kkOOdlllokOOOxdoocc::ll;..';;;;,,,,;;;;;lxOOO0KKXXX0doxxddl::xOkdkxdxllooc:cc:;,;:;::cld0X    //
//    lloxkxdoccooccc::lc''ckXX0o;'.'cdkOkkOOx:,,,lx0XXXXXKOc:OOdxOOOOkdlllldxkdoooo:,,c:''',;:c:,,,',;,;cxOOOOO0K0KX0xxxxdoc;:c::cooolcllol:;::;:c::cclkKXX    //
//    cloxxocc::oxdlc::l:',,,xX0c'';c;ckOkkOOo:;,,ldk0KKKKK0o:d00xd0KOxxoloxxdddddddc,,,'',,:lll:;,,;,;;:oOKKXKKK0O0KOxxxdolc,,::cccc::;':l:,;:cloc:clld0NNX    //
//    oooooolcc:llcccccc:;;,'l0Kd,,;,:oolxOOxoc,',:oxO0KKKKKd;lkKKdlk0xloddxk0Okxxdl:'.'''',col:;,',,;;,ck0K0KX0O000Okdollllc:;;cc:cc:'.;:,,;:;:odcclodk0XXX    //
//    clodxd:;;,:c::cccc:;::,;oOOl,,:lclxOOkxl;,,,:oxkO0K0KKo,cxkOOxdddddxxkkO00Okd:'',,',,:cc:;'',,,,,;okOO00OkdxOkdoolccclc:;:ollc;,',;',::ccll:,;ldxk00KX    //
//    llodxoccccc:;;;col;,:l:',lOOl,;cokOkO0d;;;,;cdkxO00KKKo,,cdxkOkdlldOO0Odcc:;,',,,;:;:::;;,'',;;''ckOOK0kkOk0Kxodddl:;::;;:cc;;;,'.,;;:coooc:;codxO0KXX    //
//    oloolcllcc::;,,:l;,,:dd,,:oOk:,cldkkOklc:,,:cdxxO00KKKo;:codooxOkdooooc;,,;::;,',;;:c:::;,';;;;';dO0KK0OOkOK0dlol:;,',,,,,,;:,',,:l::lcccc:;;ccokxkXXX    //
//    lllolllll:;::,;lc,;;;xkc:clxOkoccxOOdlol:;,:cldk000000dlolcoxooxdl:;;:;;:;;:;;;;;;::::c::,,,;;,;lxk0XKOkkkxdl;,,,,,,,;:clolll:::;cocccccll;,::clokKXXX    //
//    cllllccllc::;::clcc::dkc:lododxlccldoll:c;,::cx0000000oclc:::;:::cllc:;;;,,;;;;;;:cc::cc:;,,;;;lxxOKXKOxoddc;,';:cclk0kxOkooolllcddlll:clc;:clolokKKXX    //
//    cllll::c::::::::l:,;lxd:clolc:;;:,';;;::l:,;:lk0OO00K0d:;;,:c:c::c:;:cl:;;;,;;,;:c:::cc;,;,,;;cxOO0XKKOkkxdolclx000KKKKK0Oocolccddcclccllc;:looxO00KXX    //
//    :cllc::;;cddollllc;cdkdcllc:::,,,,,,'',;:;,:clk0O0000Okdooc:cl:;;;;:;;:cllllc::;:c:;;:;;;,,,,:dk0KKXK00O00Oxxk0KXK000KK0doolol:od:;clolloo:;lddk0000XX    //
//    ccc:;;:clkK0dllcc;;;lxxoollclc;,,,;;;;;cc:,,:oO0000K0Oko:;;,,;;,;:;;;;:lo::::;;::c:;;,,,,,,,;lxOKXNNXXKXXXXXXXXXK000KK0dllllllloc;clllcldc;cdxxOOO0KXX    //
//    :c:;:llldxxlclclc:,;lxxdoodddoc:;:c:;::cc:,;clk00O0KKOo;,';;,::;;::;;;cllc,',,;::;:;,,,,;;,,cdOKXXNNNXXNXKKKKXXKOxk00Oxollol::oolllllcldo:loddkOO0KXXX    //
//    cccd0XK0Ol:c::cllc::lodoccldoooool:cc:::::;clodkO0KXKOo;,::;;:::;;;;:llc:;;,;;:lc:;,,;;::;:lx0XXXXXK000KK000KXXOOKKKkolllldc;lc::;:cccdxooxxdxO0KXXXXX    //
//    lx0KKkxdllolcc::clc:cccc:cloolllcccllccc:;,:lodxO0NNXOo;;:::cccc:;;:lol:;;;:::col:,;;;;::;;o0XXXXKOOkxk0K0O0KXXKK0kxxlcloxOdlc:;,,,;ccdddkOOOOKKXKKOOK    //
//    O0Okdllodxxolll:clc:cccc:odolccc:clllcccc;,;cloxOKNWNXkc;::ccccc:;:coocc:::::llooc;::::::;:dKXXXK00OOKX0OO0KXXXKOc,clloloxOOo:,,;cc:,:dkkOO0KKXXKK0kOK    //
//    OkdllcloxkOxxkkkkxooollllloodooolloddooll:;:cdxxOKNWNKx:;ccc:::c;,;;:;:c::clccloollllloddlcxKXXXK00KKKKOx0KKKKOoc::olcldkO00xc;:cokocokO00KXXXXXK000KK    //
//    xxxdoddk00OkdkKWWX0OkO0kxdcldddddddkdloll:::cxO0KKKXK0d;,:c::c::;,,,;;:ccc:::clodxddxxkkkxcoKXKKK0000OOkk0KXK0d,':lloookKXXK0OOOkkkOO0XXXXXXXXXK00000k    //
//    OOOkxxddlc:;;;::cllok0XX0xllllodxxdddool:,;;cx0KK00K0Od;,;cccc:;,,,,;;cllllloxkOkxO00OxdddclOXKK0000kxxxx0XXX0l;;llldxOXXXXKKKXKKKKKXNXNNXXKKKKOkkxo;.    //
//    xolc;,'............''':okOKOooxollclolcc:;,;lkKXX0O0K0o,';c::ccc::lodddddoddxOOkk0KKXX0kddddOKXKKKK0Oxxxk0XXKxlcokOOOk0X00K00KXXXXXXNNNNXK0OO00x:'..      //
//    ........................';cccodxdoolllcc:,;:xKXXX0OO00l,;clcllooxkkkkk000OOOOkdddkKKK00xoxdoOKKXXXXKKXKOxOK0kdx0KXXXK00OkkOOO0KXXXXXXXXXXKOkkOO;   ...    //
//    .............................,.',;::c::c:,;ckKXXXK0O0OolodoooooxO0Okxkkkkkxxxolllodocc:,,''cOKXXXXXKKK0xxOKXKKXXXXXXK00kk0OkOK00Ok0KKKKOxo:ck0k; .....    //
//    .................',...............''''.'..,cd0KXXXKKK0dc:::;,,;;;;;,,,;;;,''''.........  ..:kKXXXNNXXKOxkKNXXXXXXXKK0OkxdxkkxOkkkxkxdlc;,co:c,........    //
//    ...''............','''....................,cok0XXXK000c.     ..  .       ..................'o0XNNXXXKOkkOXXXXXXXXKOkkxxocldlldkOko;'..;;,:;,..........    //
//    ..................''''.''..',,'...........':lx0KXX0000c...   ...............................:OXKKKK0kxdx0KKXXXXXXXOkOxdxddddol:,......''.............     //
//    .......................','.':c,...........':ldOKXKK0KKo.....................................;dO0000OkxdkKXXXXKKKKOdoddddocc:'.. .......,............ .    //
//    ....''..........''.........................::lx0KKKKKKx,....................................,ldO0O0Odod0XXXXXXKkdolllc:;'..    ..............''.......    //
//    '...,,.....''''''''',................'.....;:cdkO0KKKXOc''......................''','.''.....,okOOOOO00KKXXXXKOxxxl;..     ..  ......................     //
//    '..''''..'''''''.';,'...............','...',;:lxkx0XXX0o;;'......',;,.......'''''....'''......:dkkxkKXKK0KKKOxl:;..        ..  .......................    //
//    ,'.,;;,',;;;;;;,',;;,.';lc'........,,.....';:cldkkOXXX0o:;'.''.''',:;''''''',,';,....','.......;oxddkOOOkdl;'.             .. .................''.....    //
//    ,,''::,,,;:;;:c;:cc:,'',c:,....'...........;cccxOkkKXXOl;'..'''','',,'..','',;,'',''''''........:ooollc;'.              . .''.................''......    //
//    '''';;'',,;;;;:cllc;''',,,,'............''.;cc:d0KO0KKOo:,...''.'''''...',,','......',,..........';;...               .   ..... ...........''.........    //
//    ''',,::,,,,;,;lc:;''''',''''..'..''''',,,,';:::oKX0000Odc;'......'''.....,,'''...'''',;;,'...........          ..    ......  .. ......''..............    //
//    ,,,,,::;'',,'''''''',''''''.......''',;,,,,;;,,lKX0OkO0xc,'......''......,,,'''..''',,,;'...........      .  ..',.  ........ .....'';;'....'..........    //
//    ,;cc;',;,''...'..,,''',,'''''.......',;,,,,;::;cOK00000Oo,.....'.........,,',,,''''','.............. ..............................';,'..........'....    //
//    ,;clc;,,,..'''.''''''''';;''.......',:;',,,;;:;ckO0KKXKk:''....',,'......;::;,,,,,,;,''..'...........,,,'.....................................,'',....    //
//    ,:ccc:,;,'.............';,.....'..''':;,;,',,,;ckO00KKKO:.'....''',,..'.';cc::;,,,,'''''............',,;,....'.........................''.....'.......    //
//    ;clc:,,;,.......''......'...'''........',,',,,,:dkO0OO0O:........,'',,::;::::::;::,,,,''''..........',,,,''...........................................    //
//    ,,;;;,,c;....,,'......''...;lc;.......',,,,;;;;:oxkO0O00c........'',;:cccc:;;:c::;;,,,',,,......''.',''.'................';,'.........................    //
//    ,,;:;',;,...'''..'''.''...,looo:;,...','''',;:::oxkkOOOkl,'.......'';:;::;,,',,;;,,,,'',','...'','...'....................'......''. .................    //
//    ,;;;,'''......',:clclc:::lolooddccc;'...';,',,,:oOOOOkkOo,''.........',c;;,..',;;'','','.'..'',,;,............................................,.......    //
//    ,'....'''....,cocclodxolddoodoolloooc;'.';,.,,.':dkkkkO0d,''''''......',;:;'''',;,.,;;;'.''';,;;;,'........................ .,,..............''''.....    //
//    ''...'''''.,:looc:ccloolddodkxldxddddo:;:c,..''':ok00kkOd,....','.......,;;;,'..''.';c;,;c:'''';,'...........'.............'lkkc,.............';......    //
//    ''','....',:cdkxlc:cc:ldoddkOkdlodxxxo::dx;..;,':xOKXK0Oo:cllc::;;,''....',,'..''..',;,;:,..'..,'..........';;'''.''.......:kko;..............'c'.....    //
//    ,','.....,:cooxxolccclodoodxkxdoxddxxdoodo,..;,.:x0KKK0Oo:ldodxxxdl:,'....;:;..'...';,'''......''...............'...........'.........  ..... 'l'.....    //
//    ''''.';:clcldxxooxdlcodxdoxkOxxOOxlcoooodo,.',,,cxO000OOdcccldkxddollolc;:c;,'''...',,'.......'''.......''............................................    //
//    '''';:looooodxoodkxddodoodokOkkkOkocldddxd;.,,';cdkO00O0d;,;cxkxdl:;lxkxxdooc;,'.'''','........'........''.....'............'.........................    //
//    ',;;clolllododxdxkkkkkxooooOOxOkkdodxxddddc..,,;lxkO000Oo;:lddddxl:dxxkOdodxxxl;'''''''........'.....''..'.....''..........;:'........... .......';,..    //
//    ::ccllcllclodoxkk00kkOkdxdd0kokOxodxdool:c:..,;:lxO00Okkdcloodoodooxxdxddl:clol:::;',,,,'......';'...''.......,c:.......'',:,.............. ......'...    //
//    :lolodllolccloxkkkOkkxddddk0kooddlodxddollc...';oxO0Oxxxdcldxxoodkddkkxdl;col:,;::cc:,,;'........'.............'... ..........................'.......    //
//    ;lloddlllcldooodxdkkxoddookOkdodxdodkxodoll:'.':loxkOO0Oxclddxooxxdxkkoclllolccddc;cc,.,,................'''........... ......................,..,l:'.    //
//    ,cccoxdxddxxxdodxkOkdddloxOOOkkOOOxxkxxxkO0d,..;clox0KK0xlldooddlldkdooodddoolcodc;cc,''........................................................ .:l'.    //
//    .',',:coodddxkdlodxxdoldO0O0K0000Okk0K0OO0K0o:ccc:cx0KKOddkxxxxc:odxxxkxdddoooodolcc:..'..........................  ..........................  ...''.    //
//    ,',;;,,;cclooxkdclddddxkkkkkkOOxxkxx0K000KXXOxOOxolx000Okkxxxkxoooloolc:clc;:clolccl:.............................   ...................'..... .....':    //
//    c:oxolloc,,;cloollddoddxkkdddoc,,:;lOOOKKXXKK0OOOOO0KOOOOOkkxxkkkkxdxxddoc::::clc:;',...........'......'..................';;.......,,';;............'    //
//    xoc:::lOXko:'',::ccccoxkddkkl:::,,:okkkK0OOO0OkkO00K0kO00K0OOO0OOkxkkkkdoollccloolc'''.'.........''....''.................;;'......',looc'............    //
//    OdclxdkKKKX0xl;,:cll::clllol,'cxooxdxdodoodxxxxdxxdO0d::dO0Okxxxkdlcdkxxxxocccolccc:;,............','..''.......... ..'...''......';:od:''...'..'.....    //
//    0Ooclx0K000000kx0KXOoloooooc:oOOkdlllc:llooxkkOkoloxOxlcdkkxxdodoolcodxxdollloolc;c:'......',....'','............... .............';;,'..'..''........    //
//    XX0kddOK00K0000000KKKKKK0OOdokxllolcc:clloollxkocodddxdlloxkOxoooooodolloo::cocclc;'.............''','......................'.....'','.......'',,,'...    //
//    NNXX0kOKKXKKK00K0000KK00KK0kxxodkkl:;;::lodddxkxkxddlllcodx00xddlc::cloc:;,';cc;;::;...........''....'......................'.'....,,...''''''',,,,...    //
//    WWNXXKKKKKXXKKKK0OkO0OOkkOOO0kxxxdllllclloxOO000Kxllll::lxOOOxdxOxlllxOdol;.'',,;cl:........'..''..............',,'.';,''.....'...','....''','.',,,...    //
//    WNKKKKXNKO0K0kkkkxdxdloocccloodddoloddddxxOO0KK0Okdxxl::coxk0OkOOxkOkkOkkxdl;...;;''.........''...............'',,'',;,''.'......',;,....'''''',,,''..    //
//    NKOkkOXX000K00Okxdoolllcc:;:cccccc:codoldO000KKK00KKOxdllloxOO00OkkOOOOOOOOkl''o0ko,.....'''''''.............................',,,,',,....'',,,,',.....    //
//    KK0000XXKKKKKKKKK0OxdddxkdlolcccccodxxdodO0000KKKKK                                                                                                       //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract FnF is ERC721Creator {
    constructor() ERC721Creator("NATURE", "FnF") {}
}