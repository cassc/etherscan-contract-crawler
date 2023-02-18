// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Skyliners
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//    ,,,,,,,,'',,,,,,,;;,,,,,,,,,,,,,,;;,,,,,,,,,,;;;;;;,'.',;,;;;:;;;;;;:;;;;;;;;:::;:c:;;,;;:;'',;;,,,,,,;;,,;;,,,,,,,;,',;::::::::;;;:::;;;;::;;::;;;,,,;;;,,;,'''    //
//    ,,,,,'''',,,,,,,,;;,,,,,,,,,,;;,,,,,,,,,,;;;;;;;;;'..';;:;;::::;;;;;::::;;;,,,;;;;;,,,,,,,'',,;;,,,,,;;;,,;;;;;;,,,,;;,,;;::::::::::;;;;;;;;;;;;;;;;,;;;,,,,;,''    //
//    ,,,;,',,,,,,,',,,,,,,,,,,,,,,,,,,,,,,,,,;;;;;;;;,'.';:::;,';;,,;;;;;;;;;;,,;:;;;;;;;;,,,,,'',,,,,,,,,,,;;,,;;,;;;;,,,,,,,,;;;;:c::::;:;;;;;;;;;;;;;,,;;;;,,,;;,,    //
//    ,,,,,,;,,,,,,,,,,,,,,;,,,,,;,,,,,;;;,,;;;;;;;;;''',:::;,'.''',::;;;;;;;,,;;::;,,,,,,,,,,,,'',,,,;;,,,;,,,,',,,'','''''',,'',',;:cc::,;:;;:;;::;;;;;;;;;;;;,;;,,,    //
//    ,,,,;;;,,,,,,,,;;,,,,,,,,,,,,,,;;;;;;,,;,;;:;,.',;::;,'.',,',;;;,,;;;;,,,;:;;;,'''''',,,,,'''',,,,,,,,,;,'''''''''''''''''',;,',:ccc:,;;;;;;::;;;;;;;;;;;;,,,,,,    //
//    ::;,,;;;;;,,,,,;;,;;;;,,;,,,,,,,;;;;;,,;;:;,'..;:;;,'...'',;;,,,,,;;;;,'',,;;,,''',,,;,,,,,,'',,,,,,;,;;,''''',',,'''''';,''''',;:ccc:;,,,,,;;::;;;;;;,;;;,,,,,,    //
//    ::;,,;;,,,;;;;;;;;;:;;;;;,,;;;,,;;;;,.';;,'...;:;,'....'',;:;,,,;;;;,;;;;;;;,,;:::;,',,,''',,,'''',,;;;,'',;;;,,,,,''''';;''''''',;cc::;,,,,,;;::::::;;;;,,;;;;,    //
//    ;;;;;;;;;;;;;;;;;;;;;;;;,,;;;;;;;;;,........',;,''...,,;;,,,,,,,,,,,,;:;;;;:;,,;;:;'''''''',,,,',,,,,,,,'',,,,'',,,,,,'''''','''''',cc:c:;,,,;;;:;:::;;;;;,;;;;;    //
//    ;;;;;;;;;;;;;;;;;;;;;;;;,;;;;;;;;;,........',,''''',;::;,,,;;;,,'',;;;;::c:;,,',;;,,,''',,,,,,,,,,,,,,,,,,,',,,,,'',,,,,'','''''''',;:;::;,'',::;;;;;;,,,,;;;;;:    //
//    ,;,,;;;;;;;;;;;cc:;,;,,,,;;;;;;;,''......',,''''',::;,,',,;;,''',;;;;,,;:c;,,;,,;;;;,,,,;;,,,,,;:;,,,,;,,,,,,,,,;,',;;,;,,,''''',''',;;;::,''',;;;;;,,,,,;;;;;;c    //
//    ;;;;;;;;;;;;;;:clc;,',,;;;;;;;;,'.......',,''..';::,,'',;;,,'',;;;,,';cc:;,,,,,,,,,,,;;,;;;;;;;;;:;,,,;::;,,,;;;:;,'',,;;,',,'''','',;;,;;;'''',,;;,,,,,,;;;;;;;    //
//    ;;;;;;;:;;;;:;;;;;,,;;:::::::;,'.....'',,'''..',::;,,;;;,,,,',;;:;;,,::;;,,,;,,,,,,;,,,;;;;;;;;;;;;;;,,;:c:;,;;;:;,,',,,;;,,,,'''','';:;;::;',,'',:cc;,,',;::;,,    //
//    ;;;;;;::;;;:::;;;:::::::::::,'......'''''''''',;:;,,;:,,,;,,',,,;,,,;;;,;;:c:,,,,,;;;,,;;;;,;;;;:;,,;::;,:c:,,,;;;,,,;,,,;;;,,,,'',,'',;:clc,,,,,,;:;;;,',:::;;;    //
//    ;;;;;::;;;:::;;;::::::;:::;''......'''''''''',,,,,,;:,,;,,,,,,,;;;,;;;:clooc;;::c::;,;::::;,;:;;;;;;,;cc:;:c:;,,:;,;;;;,,,;;;,,;,,,',;,,;:cc;,'',,,,,,;;',:::;;c    //
//    ;::;;cc::::;;;;::cc::;;:::,''.....'''...''''''''',;,,,,,,,,,,,,;;;;;:odxxolccldxxocccccc:;,;;::,,;;;,;ccccc:cc:;;,,;,;:;,;;;;,,,,,,',,,',:cc;,,',,,,,,,;,',,:c:;    //
//    ;::;;;;;;:;,;::::cc::;::;,'''...''....''''''.''',,,,,,,,,,,'',;;,,:lxkxkxll::lxoc:lddooocccllc;,;;;;;:clllllccllc:::;,,;;;;;;,,,,,,,,,,'';cc;;;,',,;;,,,,',;cl::    //
//    ;::;;;;,;;;;::::::::::c;'''''''''...''''''''''',,'',;,,,',,,,;;,,cxdodoc;;;;:::::clllddooool:;::;;;:;::ccllllc::clc:;,,,;:;:;,,;;,;,,,,,'';;,;cc,'',;:c:,,',:c:;    //
//    ;;;;:;,,,;::::::cccccc;.'',,'''''''';;,''''''',''',;,,,,'',;,,',cdo:ll,,;:;,,';;;;,,:cllodol:;;,,,,:c:;:::cllll:;:cc:,,,;:::c;,;;,,,,;:;,',:c::cc,'',:cc;,,,;cc;    //
//    ;:::;;;:cc:::::cccccc;..',;,,''',,'',;,'''.'',''',,,,,,,,,,,,'.coc:;:,',,,,,,,,,,;:::cclllc::;,,;:loc;,:cc:cllllc;;:lc::;;:ccc;;;,,:;,;;;',;;,',;:;'',,;;,,,,;::    //
//    :::;;;:ccc::::cccc::;''''',,,,,,,'..''''''','''',,'',,,,,,,,,,.,:,',,''''''',,,,;;;:cllodxdoollloooc,,;;;:l::loooo:,:clcc:;:ccc::;,,;,,;;;',,,;,';:;'';;::,,,';:    //
//    :;;;;::cc::clcccc::,'''..'',,,,,,'''''''',,'''''''',,,,,,,;;,,'.',,,',,',;:;;,;:ccllodxdxkkkkkxolll;,,;;,,:l:;llodo:;;cllc:coolcc:;,,,;;;;,',,;,,,;:,',::c:,,',;    //
//    ;;:::::cccccc:cc::;'..'..'',;,,,,'''''',;,''''''''',,,,,,;;,,'';lododd:,cllcc:;cllclodxxddxxdlclol;,;;;,;;;coc:lloooc;,col:;cllllo:;,,;,,;,'',,,,,,;:,';ooc,,,',    //
//    cc;;:ccccccc::ccc:'...''.'',;;,,,''''',;,'''''''''',,,,,,,,'.',;;:dOkkl';ooolclkOOOxoloddddddc;:ccclc;;;;;,;coc:lllddl;,:loc::coddo:,;::,,,,,,,,,,,,;;,':l:,,,,'    //
//    :;,;ccccccc::ccc:,..':;''.'',,,,,','',;;,,,,,'''''',,,,,,,,'''''.,loll:,',odlldxkkOOdllllllllc;;;cl:'';;;;,,;coc:lccodl;,:odl:codoccc:ll:,,,;:c:,'',;;:,,;,'',,,    //
//    :;;cccccccc::;;:;'..',,''.'',,,,,,,'',,,',,,,,,,'',,,,,,,,,',,';;',;:;:;..;dxollcc:ldolc;::;;::;,:c;',;;;,,,,;:lc:cccodl;,codl:;loc;cclllc,,,;ld:,',;;;;,,,'',,,    //
//    :::cccccccc:;';:,...'..,,'',,,,,,,,',,'',;;,,,,,',,,,,,,,,,,,'':;..,;;,,...:k0x:,,'',;;;,;ll;,;c:cc;;;;;;,,,,,,;c::c:;col,,cool;;lo:;cllllc,,,;ol,',::;;;,,,,'',    //
//    ;;ccccccccc:';c:'...''..'',,;:;,;;,,,'',;;,,,,,,,,,;;,,,,,,,,'':;..,;;,,,,..cOkl:;,,,''''',cl:;col:,;;;;;;;;,,;;;:;:c;;coc,;cool;:oo::cllol:,,,:l;'';cccc,',,'',    //
//    ;:ccccccccc;';c;''..''.',,,,,,,;:;,,,,,,;,,,,,,,;;,,,,,,;;;;,..''..,:,.';;;''lxc,,;cc:;''..,c:,::,',;;;;;;;;;,,::;;:lc;;coc,;lool;:ooclloool:,,,::,';looc;'',,,,    //
//    ;cccccccccc;';:;;'''''.',,,;,,;;;,'',,;,,,,,,,,co:,,,,;;;;;;,''....','..'',,''cl:;,col:,'..':;,;,',;;;;;,,,,;,',:lloolc;;co:,:oool:coollllllc,,,;:;';looc;,',;,,    //
//    ;cccccccccc,';::;,,''',,',;;,,;,,,'',,,,,;;,;:oxxc,,,,;;,,,,,,''''..,'..'''.''.,;;;;;;:cc,';c:::,;::;;;;;,,,;;'.,cddoooc,;lo:;coool:lolllllll;,,,;;',:loc;,',,,,    //
//    ;cccccc::cc,';::::;'.';,,;;,,;,,;,'''',,,;,,;lddxl,,,,;;,,,;;;;,'''..,',:c:;::;,;;;:okO0Okdkdc:...,::;;;;;;;,,..,:clollc;,:oo::loooc:lollllclc,,,'''';ll;,''',,,    //
//    :ccccccc:c:'';cc::;'.'',;;,,,,,;;,''',,,,,,::;ccco:,,,,,,,,;;;;'.....',;:::cllccokOdxKNNNKKOc,......';;;;;;;;'.'::;::cllc;,colclooooccoolccccc;,;'''',cc,''',',,    //
//    :ccccc:::c:'.;c:cl:'.''',;,,,,,,,''',,,,,,:c,.cc,ll,,,,,,,;;;:,.......,:::cllol:ckNNKXNNXX0c..........',;;;;,'.;c::;,,:clc::cllloooolclolllccc:,,,,,,,:ol;'',,',    //
//    :cccc;,:;::'.,c:cl;'.''',;;;,',,,',,,,,',,,,'.:c,;lc,,,,cl;;c;.........;::clllc;;oKNNNNNXKl.............,;;''.,:;;;'';;,,;:::ccloollllloolllcc:,,,,,,,,:c;'',,',    //
//    ,:clc,,;,;c'.,:::c;'''',,,;;',,,,',,,',,,,''..';,':o:,,,::;c:........ ..,;:cllc:cd0XNNNKxl,.............',:,.,c;',,',:,'.',.';:cooooolloolllcc:;,,,,'',,;;',;,''    //
//    ':llc;::';c,',:;;c,'''''',;;'',,,','';:;'.,,'..''',:cc;;;;cc'..........,,',;::;;;oOXX0dc::'.............',:::c;'.'',;,'.''...,;:loooollllllllcc;,,,,,'',;,,',,''    //
//    .,cll:,;',c;',;,,;,''''''''',',,'',:cl:'........''',:lc;,;lc'....... .,;,,,',,,;:d0Oocccc:. ...........',,;:c:,'''';,..''...lkl,:lolcloxkdc:lc:;,,,,,'';;,;,,,,,    //
//    .',cl:','':;'',',,'';;,''''';cc::llc:;,..'.......''''':c;,,;:;'..... .;:;,,;;;,,,;::lk0olc...........;;,:llc::;;:,,,.......oXO;,:clodkkkdl:;cl::;,,,,'';:;;;,,,,    //
//    ..';c:',,.,,'''',,,',;,''','';clodl,...................,::'..:lc,.. ..;::::;::::::lkKXkllc. .......,:;':ooccc::c;,,'.'...'oKWk,':cokxoccllc;:lc:;,,,,,,,;;;,,,,,    //
//    ...';:,''..,,''',,''''''',,,;;:,',::'...................';;...;:;:,..';::cc::cldxkKNNOlcc;.......,;;'';ccccccc:;:;,.....,xXNXd,',,,;::;clcc;;ll:;;,,,,,,;;;,,,,,    //
//    ....':,''''','.'''''''''',,;,,::,.'','....................'...''..,,;clc::cccoxOKK0Oxl:c:;.....',,''',:::::;;,,;;'..'..,kWN0d:,;:;;::;;:c:::,cl:;;,,,,',,,,,,',,    //
//    ....';,;cc;',,'''''''',''',;;::coc,..,::,.''..........................co:coxodxocccooloc::;'',;,''''',,,'.'''''''.'::''oK0o;;;:cc::;;;,;;;;;,:c:::,;,'',,,,,,,,,    //
//    .....,',coc,','.'''''''',,';c:'',::;'.'::,coc:,.......................:olccxxoxxl::ddddc::,;l:'..''.''......''..':ol,,oxoc,;::;;;,,;;;,,;;;;,;c:;:;;,,,;;;;;,,,,    //
//    ,....''.':l:,,'.'''''''',,,,;;;c;..''.',,,cdddo:'..................'...,cc;colcoxdlloollol,;:'.''''...''...''..,dOd:clc;;;,,;;::;,,;;,,,,;,,,;c:;:::;,,,,,,,,,,'    //
//    :'.......,c:,,;,'''''''''';:,',,,,,,''''..':ll:;;;,;lc,...........':,..':;.';cclll;;llc:cc,;c,.'.....''...''.'l0XOl;,;c::;;:oc,,,,,,;;;;,;,,,,c:,;c:,,,,,,,,,,;,    //
//    c'.......';:;,,;;''''''''',;,.,'...','',;'..',,''''cxxoc,..........''.:l:'...',;;:;;:;,;::,,c;.''...'...;l;,ck0koc:;;:;,..,oOd;;,,,,,;::;;;,,,::,;c:,,,,,,,,';::    //
//    :,.'''.'..';clc::;,''''''''';,.,,.......',;,,''','.';;;;,,;'....''...':l:'''',::;;;,:loolc;'::...'''..'cdo;cool:;;,'..'',:dOOo;;,,,,,,,,;;,,,,:;,;c:,,,,,,,,',:c    //
//    :,''..'''..',;;:ol,''','.'cxx:'',,.........',,''';::c;'...;:''''.....':l;.'',::::ll;cddddl,':c,..'''.,oxoc::;;'......':coxkOkc,;,,,,,,,,,,,;,,;;,,:;,,,',,,'',;:    //
//    ;,'...''''..''.'cl,,;,,,.,kNXd;'...','..''...'','',;coollodo,';;....''cl,..',cl:::c:lddoc;'.,ll;,co:clc;;,,'.','....,:looloooc;,,,,,,,,,;;,,,,,;,,;,',,',,,',;;;    //
//    ;;,''''',,'.,:,',cc;,,,,',dKOkxlcc:cdxdddc;,,'','','..,;codo;.....''.,cc,....,;::cc:cc::clc,':kd;;;,,',,'.',,;:,';ll;:ldxxxdlxkc,,,,,,,,;;,,,,,,,;;,,,',,,,,,,,;    //
//    ;:;,,,;:,,'.':l:,,:c;'''';dOxdxOOkd:cooddcloo;'...;c:,',,;:;,;,;;,c:;::c;''''''',;:,cdxkOOx:.,lo:,'':ll:..;:;;:c:lxc,;;:clodddkd;,,,,,,,,,,,,,,,,;,,,',;,,,,,,;;    //
//    ;;,,,:cc:,'..,:::;,,,,',:d0OooxkOO00xooxxxxddlcc;,cdxdddl;,,,;',,';cl;,;;;,;clllodo:lxxxxxxc',ckxlclloc'.,ccclc;cxx:,;;:clllol;,,,,,,,,,,,,,,,,,,,,,,,;;,'',,,,,    //
//    ;;;;,,,;:::;,,,;;:::;,,,;:oxo:codk0K0kkkoccokOOkc,cdodkOk:'';lc;;;od;''';;,,codoodoclkkkxxxl;,,okxkxdd:':cloc;,,oOl,,:cllcc::loc,,,,,,,,,,,,,,,,,,,,,,,,'',,,,,,    //
//    ',,;;;,,;:ccc;'',;,,:c:;;;,;loddlcccoddxxddoox00x;,,;dKKx;.';looxdxl..,,,:;;:ldoool:lxxxkkxl::,cxxkkdoc;lc:c;cocll,,;:ldkkxllx0Kd;,,,,,;,,,,,,,,,,,,,,,,',,,,,,,    //
//    ,'''';:;,;:;;:;'',,';:::;;::looxOOdolc;;:clollloc,'':xKkoc;:ccloxxd:''',,::;;;:ccoocdOOxoooc;:;;dddkxc:loclxkkkl:;;;::loxk0OxkOKXd,,,,,,,,,,,,;,,,,,,,,,,,,,,,,'    //
//    ;,'''',;;,;;;;;;,,,,,,;:;,;cll:;cooc:;;;;::::::;',,,,;cdOkocoxodxko,,,,,;::;:::ccll:clllllol::;'lxdkxccdlcoooOKo;;;cllloxkO00Odk0l,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,    //
//    ,,,,,''';;,,,,,;;;,,,,;::;cxdodolloxkdlldkkxdo:''',;::lool:::oxxkxc,,,,;;::,,:::col;:oolc:ol;:;.:dlldcco::lcdXNOolcclloloxkO0Odxd;,,,',,,,,,,,,,,,,,,,,,,,,,,,;,    //
//    ''',;,,;;;,,;,,,,;;,'';oxdxxxkOOOkkO00OkdoxOOdc;ldoclx0Odlcldk0Okd:,;,';;::,:dxllll:loloodo:,::,,odlkdoo:cdOXNWKko:looxdooddxkkkl,,,,,,,,,,,,,,,,,,,,,,,;,,;;,;,    //
//    ;,'',;;,,,,,;:;,,;;;;,:dddxdxxkkkxk00dc::dK0xlcoOxc;ckKKK0Ok0K0O000Okd;;;::,;coxxkxoxkdol:,,,;:,'cxdxxOkx0XXXKOdc::lddxkxooodk0kc,,,;,,,,,,,,,,,,,,,,,,,,,,;;,,,    //
//    ,,'',,,,,,,,;;::;,,,;;:dxdddddddolxOd,.,;okxxxdoc;,',cd0XNXkoxkxk000Od:::cc;,,;:clllol:clol;;cc,;cxkdOOkOOkxolc:cclllloolccokOOxc,,,;,,,,,,,,,,,,,,,,,,,,,,,,,,,    //
//    '''''',;;,,'',,;::;,,',dOdllodoc;,cxo:,''cko;'',cdoc::lxKNNk;,:cllcc:::c:cl::lkkdoc::lxkOK0dclcc:;dkdolokxlcc::ldoolllcclloxkkkkxoc;;,,,,,,,,,,,,,,,,,,,,,,,;:;;    //
//    '''''''',;;,,,,,,,;,',lOx:,;;;cc'.;dkxoolcl:,,,'cOK0koclxOX0ddolcloooool;:l:;xKd:;:c:lkOkxollolc:,cxdododollc::loooolloxkxxkkxOKK0kdc,,,;,,,,,,,,;;,,,,,,,,;::;;    //
//    ,',,'''''',,;;;;,'';okko,.,;'',cc,:xodKXklll::ldxxOKX0c;coxxk000OxoodxOkocol;lOxc:clcoxdlccodo::c:cdxlclooolc;;lxkkkxkkkxxxxxkkOKX0ko;',,,,,,,,,;;,,,,;;;,;;;;,;    //
//    ',,,,,,''',,;,;,,''o0Oc'.,c'..'lo;;cldKXXklcco0NXKOOOd;:dkOOOkOKKXXKOxkkkkkdlcoolclddddxxk00klcc:::oxocldoolc:c:oOOkxxddolllllclx0KOxc,,,;;,,,,,,,,,,,,;;;;;;:;:    //
//    ,,,,''',,,,,;,,''';xkl'.'lc...;oc,;,,ckkdc'''cxOKXXKOc':kXXKKKKKKNNNNNXKOkxkOxdodddxxO000Okxdoooccclkxlodollcclclxkxoc:::;;::::cldkdkd,,,,;,,,;,,,,,,,,;;;;;;:;;    //
//    ,,,''''',,,;;,,,,,lkc,.':l:...;:;::,':l:,;::;;::lkXNXklok0KXXKXNNNNNNNNNNX0kkkkkxxoxOkddxxdoooxOkdolxkdddollcclcccllccc:;;;;;:clllcl00c,,,,,,,,,,,,,,,;;;,,;;;;;    //
//    :;,,',,'',,,,,,,,:x0o;'.;:,'.'::;:::;col::cldxxdoox00xkKKOOXXNXKXNNNNNNNNNNXKOOXXX0kocccokOkxkOkdoocdkxxdoolllccclc:;;;;::;;:::cclclxkl;;,,,;,,,,,;;;;;;,,;;;;;;    //
//    :::;,,,,,,,,,,,,;okkocc'.;,..',c::xkooxxccxOKX000o:cld0KOkOKNX00XNNXXNWNNNNXXK0KKXNXOdoollodxkdoldolokxdddodolccllcc:cc;;;:::cc:::c:;,,,lc,,,;;,;::;;;;,,,;:;;;;    //
//    ,,,;::;,,,,;,,,;:dxxocoo:::;'..,::ok0K0xccdOKXXXOlclox0XNNNWWKkOXNNNWWNXNNNNXXXKKKKXXKKXKOkdxOOxoddloxkxxdoolccccccccdOo::;:ccc:;:c:;;::xx:,;;;,:oc;;;;,;;;;;:;;    //
//    '''',;::;,;;;,;;;lxkxddolcol:,..',;:lxkkxxxoloxxxddxxkk0XNNNNKkx0NNNWNNXXXXNNNNNXXXKKKKKXXXK0kxdodoloxkxxkdllcccccc:cxKOdlc:ccc:;:::clc:oklcc;;:llcc:;;;;;;;::;:    //
//    '''''',,;,,,,;;;,:xOkkko:,;:::;,,',:llldkOkkxkxllcldxO0KNX0KXKXXXNNNNNNNNXKK00XNNXXXXXXK00O0KXK0OkxooxOkxdoodlcclc::clddoc:;;;;;;:cloocccldxl:::::c:;:;;;;:;;;:l    //
//    ;,,''''',,;;,,,,,;oOOOxlcc,'',;;cc:;;;;:clldkkdc:;:cclx0XNNNNNNXKKXKKXNNNNNNKOk0KXNXXXXXK0Okk0000000OOkdoooxOoccc::coo:;;;::;::cllloxl;cdokOl::;;;;;:::::::;;;co    //
//    ::;,'',,,,,;;;,,,,:dkkOOkxl:;;:ccc:;:::;:c:::cllooc:;codk0KXNNNNK0X0kk0XNNNNNNX0000KKXNNXK000KKK0OOOO0KK0Okkxlccccccdkdc:;:cc::cc::coc,:olclc:::::::;;:cc::;;cod    //
//    ;,;;'',,',,,;;;;,,',,;:cloool:::;,,,;::;::;colllloddoloodkkO00K0xx0NNKOkkKXXXKXXXXXK0OOKNNXXXXXKXXXK0OOOKXXX0kdooddlxOxoc:clcc;;::::c:,:lccc::::c::::::::::;:lok    //
//    ,,,,,,,,'',,;;;;;,,,,,,,,;;;;;;;;:;,,,;:::cdOkdolcldkxxkkkkOOkOOkk000XNK0O0K00XK00KXNXKXXKXNNNXXXNNNNXXKK00KXNK000000Oxo::lllllc:c:::::cdddl:cc::::::c::::::loxO    //
//    ',,,,,,,',,,,;::;;;;;;,,,,,,;;;;;;;;;;;;:;cOKOkOxloddxO0KK0kkOK0O0XXKXNNNXK000K000KK0OKK0O0KNNNNXKKXNNXNNXK0000KXNXKK0kxdlloccllodolcloldoccc:::cc::coo:::::cdOO    //
//    ''''',,,,,,,,,,;::;;;;,,;;;;;,,,,;:;;;;;;:lk0OOK0O0OddOKXXXK0KXKO0NXKXNNXXKKXXXXXXKXK0K00KOO0KNNNXXXXNNNNXNNK0OO0X0kxkkkkxkxllc:cdxdlclldocllc::ccc:cloc::::oO0k    //
//    '''''',,,,;;,'',,;::;;,,,,,;:;,,,,;;,;;:;;:coxkOO0KKOOKK00KK0O0kdONK0KKKOk0XXXXNNXXKKXXXKKXXXKXXXNNNNXXXNNNNNXXXXNX0xdddxdkOxlllc:coolldxdoxdlccccccc::cc::lk0OO    //
//    ''','',,,,,,,'''',,;;;;;;;,,,,,,,,,,,;;cc:;;looodxxO0KXXKOkxxxxookXXK0O0KKKXXKKXXXKKXXK0O0XNNXKO0XNNXNNNNNXK0OKXXXXNXX0Oxdxkxololcclolclooodollcccccc:ccc:lk00OK    //
//    ,,,,''',,''',,,',,,,,,;;;:;,,,,,,,,,,;;;;codool:ccldkO0XXX0kddxxddxkOKKKXXXXXXXXXXXXXXKkx0KKXXXK0O0XXXKKXNNXKKKXXKXNXXX0OO0XX0OOxolloolllooolllllcccccccclkO00KN    //
//    ,,,,,,'',,',,,,',,,,,,,;:::;,,,,,;cc;;c:cxxc;coc:::cldxxOKKOxdxxkOkxkO0KXXXXXXXXKKKXXK00K0000KXXXK00KKOk0XXNNNXK0O0XKKK00KKXXXXXXKOxxdolloooolllllccccccok0K0KNX    //
//    ,;:::;;;;,,,,''',,,,,,,,,;:::;;,,;cc::clcll;,;ll:clc:clocldk0OkOOOOkkO0OO0KXXNNXXXKK00KXKKK0O0KXXXKK000KKKKKXNXK000OkkOKXKKXXK0kxxxxdxdoodxxkxdolllllccokO0kd0Xk    //
//    ,,,,;;,,;;,,;;'',,,,,,,,;;;::::;;::;;::cccooc:cccldoccol;,;:lxkOOkkOKKK0OkOKXXXXXXKOkOKKXXXXKKKKXXKKK00XXXKO000KXXK00KXXXX0Ok0XKOOOOO0OdodkOkdxxollodolxOxoccxkl    //
//    ,,,,,,;;;c:;;;,,,,,,;;;;;;cl:::::::;;cdool:ldl::oxxlcdd:,;::;;:codxk0KK0OkO0K00000Oxdx0XXXKKKXXKKXXKKXXXKKKOOO0KKK0KXKKXXXKK0KXXKXXKKXKOkxkkoloollldddddolclxkdd    //
//    ,,,,,,,;;;;;;;;;;;;;;;;;;:cc::::cc::;coodc;:ll:coooloo:;,,:odl:;::ccldk00OO0K0OkkkkOkx0XNNXKKKXXXXXXKKKXXXXKKXXXK0000XXXXNXXKXNNNNNXXKOkOKXKkdoodolldkxlccd0Ool:    //
//    ;;;,,,,,;;,;;;;;;;:;;;;;;;;::::::ccc:lol::clccclollxd:;;;::ol::cccccclldOK00KK0OkkxkOk0K0KKXXXXXXXXNNXKKXXKKXXXXXXXKKXXXXNNXXXNNNNNNXK0O0XXNNK0OxoloxxoclkXKOOkd    //
//    ,,,,,,,,,,,,,;;;;;;::::::;:::::::ccccodl:codlccclodkl;;;;;:c:;;:cddoolod0XNXK0OOOOOkkkOOkxxkO0KXXNNNNNK00KK0KXXNNNXXXXXXNNNNNNNNNNNNKOO0KXXXNNNNX0kxkOxoxXX0KK0O    //
//    ,,'',,,,;,,,,,,,,;,,;;:cc::::::ccccccdxoc:lolcccldOd:;cl:;;;;;;;cdxdlclodxOKXX0OOkxdxxkOOkdoodkO0KXNXOdloOKKXXNNNNNNNXNNNNXKXXNNNXKXXXXXNNNNNNXXNNX0OkkOKNX000Ok    //
//    ;;,,;;,,,;,,,,,,,;;,,;;:::::::::cccccdkdc:cclocclkOc,;lo:;;;:::::colccllododO0OOkxxdoxkOKKOxlloxk00K0kdodk0XNNNNNNXXNNNNXNNNXXNNNNNNNNNNNNXNWWNNNNNNKOkk0KKxoxO0    //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SKL is ERC721Creator {
    constructor() ERC721Creator("Skyliners", "SKL") {}
}