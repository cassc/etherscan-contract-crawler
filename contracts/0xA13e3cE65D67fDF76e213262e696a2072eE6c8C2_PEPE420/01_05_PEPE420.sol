// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: 420 PEPE
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    ...............',;420c:;,'.........';cc:;;'','.....',,;::cloolccoxO00pepeOkkxxxxkOOk0OOkOOkxkkkk00Od:,,''...''....',,'...............................'    //
//    ..................,:clc;,'...........,:lddllol:;::;,'','',;;:llloxOOkO0kxxOOxdkkxxxxkkkOkxxolodkOOkdc;,''.',,...',,'.................................'    //
//    ...................';420:;'.............,;clpepeodolclol:;,,,,;:cok000OOkxkOkxkOkxxkddxxkxxkekxOOkxoc;'''',,',;;;'.....''''..........................'    //
//    ....................,:420:,'...............',;cllpepepepeoollllclodxkO0OkkOOOkxxxkOxollodxkxdodxkxodl;,',;;;:;;'.....',,'.....................'......'    //
//    ....................,:420:,','.....'',,'',,,,,;:cllpepepepepepepepeodxOOO0OkOkkxdkekodxxxxxxoodxkxlc:;;;:;;,'.....',;;,'''''''.''...''''.....'''.....'    //
//    ............',''...',;::c:;;,'....'',,,,,;;;;;:::::::cllll420llllllccdxdk0000K0OkkekxO0OkkkOdldkOkdl:::;;,'',,,;;:420c:clc::420c;,,''''''''''''''....'    //
//    .............,,;,'.';::cc:;,,'.....''.................'''',;:clloool420coxkkOkkOOOxodxkkOOOkdoxO0kl:::;,;::420cclllc::420c::cllcc:clc;'''''''''.......    //
//    ...............',;;;::cc:::,.......,:;',,,,,,,'',,,,;;:::cllll420420cll420ccloddxkkkxdxkOOkdodxxkxl:;;;:cc::;;;:::;;:::::::::::;;;:clc:,'''...........    //
//    .''..............;:420c:;;;;''......;l:;;;:::clllccloollooc:::;::lolllc;,,,,,:lllloddodxkOkkdllc:;;,,,;;::::,',,,'',,'''''',,,,,,,;;::420:;,''........    //
//    ..''.............':lllc:;,,;,'.......,lollllclooollldollodolllllllcc;,,',;;;;420420lllloolodocc:;;::clccllll:;::::;',,,;;;,,,'''..''',,,,;;;,,''......    //
//    ...'''.........''.';lll::;,'''........';coddkekllllll420420::::420c:::cclll420420clollllllloollclllllllllllllllllllclllloolll:,',;;::,''.'''''''''''..    //
//    .....'''......'''..';cc:::;..............,;cllc::::::::;;;;;;:cllllllollllcc::420cclolllllllll420ccllll420lll420420llpepeoodolcllool;,,;:cc;,;cclc,'..    //
//    ......''''''',,''',;:;:c::;................',;;;;;;;;:::::clllooolllllllllcc::clll:::clllllllllolc::;;;,,''',,,;;;::cllpepepepeooddlllpepepepeoo:'....    //
//    .......'','',;;,,,;cc:::cc;',,,,;;;;;;;;;;;;;;;;::cllpepepepeoollllcclll420420cclc:;,,:cllllllllll420c::;;;;;;;;;;;;;;;;;;::ccllllloolllllllcc:;'.....    //
//    .......''''''':c;,:420420420llltommydddddddpepeodddpepeooollolclolc:420420:::420:::;''',;:clllllllloll420:::;;,,,,,''''......''',,;;;;;;;;;;,,'.......    //
//    .....''''''''';lc:llc:::;,''''',,,;;420cc::cpepeokekollllllllccllc::c:::c:::::420c;,'''''',;cllllllllll420420:;;;,,'........................''........    //
//    .....''''''''';ollddl:'................'',;cpepeoollllllccllc:clc:,;::;;;;;;::420:;,',;,,,',::cloollllllllclllllll420:,''.................''''''......    //
//    .....''''''''';lloddoc,...........',;;:cclpepellol::coo420cc;,cl;''',;;;:cc::cc:;;;;,;l420cldddxkOkxdollollodl420420lllcc::;''.......'''''''''''......    //
//    .....'.....''',codxdo:,.........',;cpepeooollclool:lollc;;;;::oxl:;,,;;;clc;;:;;;;:cloxkkkxxkkpepe000Oxxxxxxdol420ccllollloolc:::::;''''''''''''''...'    //
//    ..........'''',cxxxdl:,......';:cllollllll420odoc:;:ddoddxdddxkkkxolllool:;;;::lxdxkkkkkOkxxkxxkekxkxddxkOOkddolllllllllllllllllllcc:;;;;;;;,'''''...'    //
//    ..........''',cxxdddl;'......,cpepeolloollc::c:;:lodkOOOkkkkdpepel420llc:::cldxkOOOkxkkOOxdollc:;;:llccloxxkxkxdl:coc;;;::ccllllllllllccllc:,''''.....    //
//    ..........'',:dxddoc:;'...,:coxdlc:;';ll:,'..':dO00OkxddxxOOxdlcc:;,'',:lodxkO00OkxxxkkOOkkdlc:;,'',;;:420lloxkkxool;,,,,,,;;::::420lol420420::;,''...    //
//    ..........';clddll420c;':420:cdxdc,';c;';:;:ldk0K0Okxollooodol:,,,,''':xpepeOkOOkxxxddkkddddolc:,'.'',;c:clollodxxc;;,,,,,,;;;;,,;;;;:::420420cc:,''.'    //
//    ........',:cl::420420c;;;,'.;oxkxoc::,.'oxxpepeOOkxxxdoc:;;;;,...''',lxpepeOkxxkkdkekllodl:::;;;;,,,,;ll:cllc:;cdkd:;;;;;;;,,'''',,,,,,,,;;;;::420:;;,    //
//    .......,clcl:';ll420cc:,...:dkkxdo:'.';lk00Okxddkekkekdol:,''....:ccoxOO0Okxxxdxxollcc:;cl:,''''',:clll:cll:;::ldxxo:;;;;:::;;,,''''..''''..''',,,;;;;    //
//    .....',lolc;'.':420cc::;'.;dkkkxdl;:odxOO0Oxolloolclloodddl;....':xOOOkkOOxxxkekoc;;;;;:;;;;,'....',:;;;:c:,,;;cdxxxlc:;;;;;;:::::;;,,''...........'''    //
//    ....';codl;'..':l420420c::oxxddddllk000Okxdpepeolcloollclol;....;dkOOOkkOxpepelcc;'''''''',,'......',,',;:,'.'',:ldxxdc;;;;;;;;;;;::::::;,,'''.......'    //
//    .''',clodc,....;lcc:ccloddxkxooocok0KKK0kdddpepeolccl:;;;;,,'',;okkkkkOOxdddol420420:,'...','.''..',,'.',,'....',;ldxdl;,,,;;;;;;;;;;;::::::lc;,,''..'    //
//    :;,';::col,....;llcclodxxxxxxkekok0KK0Okxxxxdollll:cl;,,,'',,:odkOOkOOOkxxxxdollodddoc:;,,,,,,;:;,;:;'.''...''',;;cldkxoolc:,,,,,,;;;;;:cc:lxxc::;;;,,    //
//    ooccllccloc;'..':::lxkkkkxkekxxdxkkkkxdollooddollccllc:;;;,,,cxkkOOkkkkddtommykekddollcc::cl:,,,;;;:;'..''',,',:c::ldkkdl;::;'''''',,,,:dkxxkOdl:cc:,:    //
//    ;::lpepecclll:,';::oxkkxkekccdOkkkkkkxdoc:;;::;;:::cc:;,'''.,okkOOOkxdolclllodxxddl420:;;:od;.....''...',,,,,,:cc:cloxdc;;;;:;,'''..''';okkkxddodxl;:l    //
//    ',;:codxdc;;;;::clldkkxxxdllokpepekkkxdkekdoc;,,,;cloc,'....:xpepekxollooollooddol420c:;,:l:'.........;:;;;'.,;;,,;:dkxoc;;;;;:;,'''...,okOOdlodxxdxxk    //
//    :;,,,;lddoc;,;cldkekdxollodxO000Oxxdpepeooxkdoc,',:ll:,'..';lk0Okkkkxdoddollllolllolllcc::::;,'''''''';:ll,..',,,:ccoxOkl:;;;;;;;,'''.':oddkxdddoclodx    //
//    ooc::::lolcc::ldxkxddxdllxO000Okxxxddoddodkkdlc;,,;;,''..':dkOOOkxkekc;;,,'',;;,,,;;;420420cc:;;;,,,,''.,;...';cclollokOxl:;;;;;;;;,',:cdkkxxxdlc;coxO    //
//    :lolc:codl::ccldkkkkekdkO0000OOkkkkxxxddodxxxdl::;,'....':dkkkxlc:',ll.....,;,....'..lxddkekddocc:;,,,,,';::::lxkkekodxxdl;;,;:;;;;;;lddkOkxdlcloodkkk    //
//    ':oooc::odc::loxkkkxodxO0Oxxddolc::c:::::cc:;:420;;,'...,lddl:,,ox;,lo:'';clc,.,:odc;lO0Okxoodd:,,'.',;cldxxxxkOOkxkOOkxoc;,;ll;,;;clkekkxdkxlcoxxxOOO    //
//    .';cllllpepeodxkxxddddxxl::c;,:o;........:ool420:,,;;'...:lol;'';;.;ol;,::::c;,;cl:;,;:c;,,'';;...';:coxkkkOkOOkxxxkpepekxddxdc;,,;lxkkkxxkkdodkkkxoxO    //
//    ..',cllldkekdddxxkekodo:'.:dl;:c,..:oc,';:ldddddxo::;,...:kekkkekl:;;;;;::::::,,,'',,',,,'''.....':lxkkkkxxxxkkxdddxkkkkkkkOkdc::,'cxkkkkxdllldkOOxlld    //
//    ',;;,:llodlldxxxxdodkkxo:,'...::'..;oxxlll:lddxddol:;,...;dOK00OOkxdpepelllolc:,,,,,,'',::;'...,:ldxxxxxdpepeoodolotommyxxkOOkxl420okkxxxkekl:cdkxoclo    //
//    cc;;:::lddlcoddxxkekxO00Okoc:;,,''''';cc:,,,,,,,'''......';oOKKK00OOkxxdxkxxdoc;,,,,,,',,;,...,cltommyolol420cc:;:clooolldO0Okxolc:pepexxkxxkekdlcclll    //
//    :llclllloocclodxddlclx0KK0kxddlllllccllc:;;;;,,,,,''''.....,lxO0KK00OOxdkkxddoc:;;;:::::,'..';clpepeolc:c:;;;;,,,,;cllc:looxOkxdlllx00OxxkO0Okxoccoxdl    //
//    ,:llcoolol:;:ldddollloxO000kxdollol420c;,',,'''''';:,'......':dxkO00000pepeOkdl::::;;;:;',;;cllooollcc:;,,,,'''.':olllc:llclxxxdlokOK0kooodkOkxlcoddlc    //
//    .',:cclolol:,:dxxkekoccokO00kxdddolc:;,''.''''..',;;'.......';;;:loxkpepekkxxolool:;,,'..,odollll:;;;:;;;:;;,'...,;,,;;;;;:codkekk00Okkekdododdlcclolc    //
//    ;;;:cllpepel:codxxxdol:;:lxkkxddxxddoc;;;::cc;,''''.........'''',,;:clodddollcclc:;;;;,',;:lolcc:,',,;::c:;,''......'',,;:odxxdoxkO0Okxxkkkxooolcldxdo    //
//    ;;;:420odddoc:cldkkxdll:;:odxdllodxxoc::cclo:,''..........',;;;;:::::;;:::,,,'',;,;,,,,,,;;:c::::;,,;:c:;;'''.....''''',;:clloooxkOO0Okxxdddkeklcoxxdo    //
//    '',::ccldddoc::clodddxxl:lk00kxkekddl;;;;;;,'''''....',,,,,;cokekollcc::;;;;;,;:olc:;;;:::cc:;;;;;;:::;,,'.......''',;;:420cc::ccokpepedlll420lldxxoox    //
//    :::lolloxxdl:;;;;;::lxdclk000Okkxdoc:;;;;;:clc;;c,.'',;;;;:cokkdkekddolc::::::::cc:;;;col:;;;,;;;;:;;,,'..........':lc;::c::::::;:okOOOxolc:420loddxxx    //
//    llllloddxdlcc:;;;;;;:llcoxkkkkkxxdoc:::;;;loc;:cooc;;::::ccloxkxddxkxdl420420420cc:::;:lc'',:c:::;;;,'...........',::;;;;;;;;::clodkpepekdlllolododOkd    //
//    lllccldddolc:;;;;;::;;;:clllooolcc::::;,,,,::;coodd420:cl420ccllllloolc::::::::::420:::c::::::;;;,'.............',;;;;;;;;;:c:;:clloddk00Oxddollcclooo    //
//    420lllodddl:,,,;;;:c:;;,,;;;:::420clll420420420cclllllccllll420clllllll420420lllllll420::;;;,,''...............',;;;;:::;:::::;;;;;;;:dxxxxdol:c:,,,,;    //
//    lclolccloooc:;:::cclc:;,,,,,,,,,,,,,,,,;;;;:::::420cllccllll420420:::;;:::::::;;;;;;;;;,,,'.......''........',;;::;;;clc:;;;,;;;;;;;:colloollc:;:;,,,;    //
//    c;;:;,;;:420lodolc::::;,,,,,,'''..................''''''','''''.''''''''''','''''''''''........'''..........','''''.',cl:,;::cllolllcclolllllll:,:c;',    //
//    '''',;clc::ltommyo420:,,;::::;,,'''............................''''''......................'.....'''.....';;''...'',;;:cllllool420cc:coolllllc:,':oc,,    //
//    ,;;:cllcc:clolodxddoc;,;cdxxxdoc:;,,,,,,,,,;;;;;:::::;;;;;,,,,,,,,''''''''''''''.....'.............,:'....',,,;,;;clllllolll420::420:coolllc:;,,,;cl;;    //
//    clccl420llllllpepeoo:;:cclx00Okkxo:;,,,,,;;,,,,,,,,,,'''''''''''''.................,,''''..';'......''',;;:420cc::clccllllol420420clollollllc;;;;:420:    //
//    lcclllcllll420:;;,;lollolodxO0O00Odoc:::cc;,,,,,'''''''''.....'',,''............''';llclc:;;;,,,,,;;:::cc::::;::;,,:clllllcc::420llloolooolc:;;clc:;:l    //
//    occllcc::::;;,,',;::loddolldkxdk00kkxxddddolc:;,,,,'''',,,,'',;cdl;,''..''.....''';;,,;;;;;:::clclllllllllllllcl420llllllc:;;:clldoloddol:::ccllll:;;;    //
//    :;:;,','',,,,,,;::::cdxdlccloooxkkkkkOO00000kdollcc;,,,;:::::::loc,,,,:cc:,''....,c;.....'....',,,::;;::420clllllllll420c:::clpepelllclo:;::cldxxo:;;;    //
//    ...',,;;;;,,',:cc::::codolllotommyxxkpepe000Oxxxxdoc:::ccloxdlc:;;::;;::,''''''..';,....';,....'''''''',,,'',;:cloolllclllooloooloolcclllcc:lddddoc:;;    //
//    '',,;;;;,,,,:clc:;,,,:lodpepepepeootommyxkkO00Okkxdolccllokxlc:::cll:;;;;,,'''''...'''''','...',cl:;'',;:ll;:cllllllpepeoollloollolllollllllooodxoc;;;    //
//    ,;;;;;,,;;:lol:;'',;cotommypepepepeootommyxxxxxkkkkkxdoddxxooloollddpepeooll:,'''''.',,,,''''''',:lc,',,,clcclooollllloolllloxolllllpepellllccloddl:,;    //
//    ;;;,,'',:cc:;'..';cclpepedddpepepepedodddtommyxxddxkkxxxxxkekodxddxxdollllool:,',,,';:;,,,;;,,'''',;;::cclllllllllcllllooollpepekekolllc:clclccloollc:    //
//    ;,'.',;;,;;'..';:ooclpepeodddotommyddddotommyxddddddpepeodkekodxxdodxdcllllllc:::c:;:l:,,;;::::::420cc:cloolllllcllllllllllpepedddolcloccollol:cdkekod    //
//    ....',,..',;,;::colcclpepeddddxxxkxxxddddotommydddkekollllllloodOxlloollc:;;;::420c::ll:clccll420:;;;::cllccldollolllccllllooolloddlcoolllcloc::odkekx    //
//    ;'.......';::;;:lolcllpepeoxxxxdxxkektommyddddddddddddpepellllllool420cc::::;;;:420cclll:::;,;;;;;:ccllllllllll420cclolodolll420lodlcllcclllc:;:lddodx    //
//    oc,.....,:420;,;coc:lllodddxxoollc;;,;::clodddotommydddpepepepeollllll420clll420cc:;,;;;;;:;::::cclllllcllcc::cc:;:loodddllllccllllccllclllllc:;:ododk    //
//    kdl;'..,:c:;::,,cl;:lldkxdddl:420;,,',,,,,;:ccllpepeoodkOOdpepepepeooollllool420::;:c:::lllll420llccll420420:;;;;:lpepedolcl420c::cllllllllc::,,,:oodk    //
//    kkxo:',;:c;,::,',;:odxxkxoooc::::::;;:clc::;;;;:clooloO0kkxolpepepepel420lllllooollolllpepelll420l420420:::;;,;cloddollolccl420cc::clllllc:;;;;;;:lodx    //
//    kkdc,,;;c:,,::'.,cdxxddollcc;;;;;;;;;;:lokekl:;;;;::ccoollpepeooollollllllllpepeodddpepellllllllclolc;::;;;;:;codkeklclol:;;;;:420::cc::;;;;::c::420lx    //
//    xxdl::,;c;'':c,:oxxdolc:;::,',;;;,,',;;;:clodxkOxl;'',,;:clotommydpepepepepepetommypepeoollllcllc::;,;::;::ccloddololclc;,,,,,;:cc::;;;;;::::420:cc:co    //
//    xxdoc;,:c,.':clxxoll:;;;,;:;'',;;;,'',,;:lx0K0Oxol;.',,,,:lootommyddddddpepeoooddpepeollllclc::;;;;;;:ll420codkekddoc:;;,,;,,;;:cc:;;::c:420:420::420c    //
//    kxdxdl420'.,:lxxo420:;;;,,:;,''',,,'';lxO0Okdl;,,,,,,,,;:clpepeootommydollllookeklllcc::c::;::;;;:c::ll420lodkeklclc;,,,,,,;;;;:c:;,;:;clc:c:;::;:c::c    //
//    xdxkdl::c,';coxoc;,,;:;;;,;;,;'.,:ldk0K0xolc,'.'',;cclllpepepepeooddkekllllookeklllcc:;;;;:::c:::cc::clllpepellc:;;;,,,;,,,;;;;:c:;;;;;clc:cc;::;,:::c    //
//    ooddxdlcc:,,:odc;'..';:::,,,;cloxOKX0kdo:;,'..',;cddddddpepeokeklpepeollclllllllc:::;,;:;:420c:::cclllooodolcc:;;,,;,,,;,,,;;:;:cc;;;:::cl::c:;:,',;,;    //
//    dddxxxxdlc,,:odc;'''.';;;,;cxOKK0Okxoc;'....''',cxxxddddpepeooollllllollcclolc::;;;:;;::420420420clddolllc::;;,;;;:;,,,;,,;;;;;:420:;;::clc::;,;,'',,,    //
//    xkkxdxxoc;,,:odl:,,;,,,;,...,lxxddoc,'.....''',;lxxxdddpepeooolllllllll420clc;;;;::;::::cclllllllllol420:;;;;;;;;;;;,,;;,,;;;;;:::cl:;;::cc::;,,,,,,,;    //
//    kkxkekoc;,,,;odl;'',;,,'...  .:oc:,.......'',,,;ldddddpepeolllllcllllcclc:;;;,,:ll:::cclllooolcclllcc:::;;;;:::cc;;;,;;;;;;::;::;;:cc:;;:cc:::,,'',,,;    //
//    xkkxddol420cldxc,'....'...............',,,;;;:clodpepepepellllllcllol::;;,;;:420l420clpepel420420lc:;;::;::cll420;,;;::::;:c::::;;420c:;,:c:::,'''',,;    //
//    xkkkkekodxddkkd:,..................'',,;;:cltommyddddddkekllll420420c;,,:cclll::clolooddollllllc::;;;:420lolllc:;;;;::;::cllc:;;,,:420c;,,;;;;,''''',:    //
//    xkkxollloodxkdl;'...............',;;::cclotommydddddkekoloodollllc:;,;:420420llltommydkeklolcc:;:;;;:clcloolclc:;;420:::cll:;;,,,',;:cc:,,;;;;,'',;::l    //
//    dxkxocloodkkdl:,..............,;;:clotommydddddddddpepetommyolcc:;;;:420c:cclodtommydolcllcc:;;;::::coolclolccllccllc::420c:,'',,,,,,;;;,,,,;,''';cc:c    //
//    xkkxoloooxOxl:,'............',;;clddxdddddddddddddddotommyooc:;;;;::::420ccllolloddoll420c;;;;;;cc::ldol420::looloolc::clc;,,'''',,;;;,,,;;;;,'',::::c    //
//    dxxdolcldOkoc,'..........''',,;:clpepellllllltommydddddddolc::;::420clllll420lllloolllc;;;;,;;;:ll::cllc;,,,;lpepel420ccll;,,,,,,,,,:cc::::;,'';cc:;:c    //
//    oookekxkkkdl;,'''........'',,;::::;,,,,,,,,,,,;;:clooloooc:::::cllllllllclllcl420lllc:;;;,,;420lolc::c:;,',,;clloolc:clc;;,,'''',,,,;:c::,;;,,,;c:;;;:    //
//    ::420ldddlc:,'.........'''',;;cl::;;;;;;;,;::::clpepellc:::c:clllollllllllll420clool:;;,,;;collool:,,;;,''',:lpepel::cll;''.'',,,,,,,;,,;,'''',::;::;:    //
//    ,;;::lddlc:,..........'',,,;:;:cltommydkekoddkekdkekol420loollpepelllllllloolcclc::;,,;::;:col:clc:,'',,,',;clllolccllcc;''',;;;,'',,'''',,,,;cc:::;,;    //
//    ;;:clxkdl:,...........',,;:cc:::::looodkekoddpepeooolccldddpepeoolllllloolllllc::;;,;;:ll::cc:,,;;;,'',,,,,:lpepeollooc,,,;:;;;,,',,'''''',,,;cc;;:;,;    //
//    ;;;cdxoc;,...........',,;cllc:c:;;;:::codpepeoollodlclloddpepeoolllllloolllllc:;;;;::lllc;,;:;,'.',,,,,,;;:lpepeocclllc,;cc:;,,''','''''''.',;c:;::;;;    //
//    ;;;;cc;,,'...'......',,;cooollllcc::;;;:clpepepepeollllllllllloollodkekolc::;;;;:cllllooc;,,,,,;:;;:c::::cloollllclllc:,:c:;;,'''''''''''''',;;;;:;,,:    //
//    ;;,;;:;''...,;.....',,,:oddpepeollc:cc:;;;:clpepelllllllllllpepepepeooolc::;;;:clloollolc::::;::420420:::llcllooolooc:::::;;,,''''..'',,'''',:c;;:;,,;    //
//    :;;,,;,....':l:;',;;;;:ltommykekll420420:;;;::coolllllllooollllooolllcc::;;;;:looloolllll420420420clolc::;;:looolcodl:;::;;,,,'''''.';::;''',::;:;,,;,    //
//    c:;;,;;'..;cc::llclllllooloodxddo420420cc::::;;:cloollpepelllllpepelc:;;;::::lodoclolclllllpepeolllc:;;;;,,;:lpepeollc:;:;;,'''''.'',:420:,';lc::;,,,;    //
//    c;;;;;;'..':l::lcclollollllc:ldkekol420lll420420:;coololllllcclpepel:;;;:cc::loolclolcllpepekekol::;;;;;,,,,:looodoc:ll:;;,'''''.;:;cpepeoc:ccll:;;,',    //
//    ll:;;;;,...,lc:lllllc:llllc:;;:oddkekol420cclccll::::420ll420llllcc:::::lol::lolclllllllooodolc:;,,;:;;,,,,:coddkekl420:;,,,,'''':olodllollocloc:;,'',    //
//    ll:;;;;;;'..cc,:lc:cc:cll420420pepeooollllccllccl420::::420:coolc:;:420:loc:cllllllllllpepeolc;,,;:;;,,,;:cloodkekllol:;,,',,''''';ldolodpepelc;;,''',    //
//    cc:::;;;:,..:c;:cclllclollllllll:;::clllllccll:;:420:::::420llll:;::clc:clc:clllllllllpepeol::;,;:;;;;,,:cllookekollol:,,'',''''.',:llllllcc:;;;,'''.'    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PEPE420 is ERC721Creator {
    constructor() ERC721Creator("420 PEPE", "PEPE420") {}
}