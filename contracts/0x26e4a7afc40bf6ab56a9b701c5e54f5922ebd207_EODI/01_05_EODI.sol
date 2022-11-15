// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Exploration of the Digital Imagination
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    .;cc:;;:oko;..,'.   ..     ........',,,,:ldddxkk0000Od,              .,:,'.           'd00K0Okdoloc.      ..,,'..  .::;,    //
//    l:'''...'oOkl'.,'.  ..'',.........'',,;:lloxkk0KKKK000k;.            .:;..  ..       .lK0OOkxdolllo:.    .','..     .;lx    //
//    '.',,;:;;okkOl'.',. ..'''.........'',;:cldxO0KKKKKKK00Ox;            ':,.            .oKOkkkxdlcccl:.   .,,...     .ckKX    //
//    .'',;;:;:looxl...''..    ........'.',,:coxO00KKKKXXKKK0Od'           .';;'..          ;OOxkkxdol:cl'  .','..    ..cxxkKX    //
//    ..':l:,,::clo,  ...''.  .........''';:clxO00KKKKKKKKKK0Ok:        ..   ..',,,,...     .;xkddoolllc'  .,,...    .lOKOxkko    //
//    .''''',;;;:c,.    ..''............',,;cdO00KKKKKKKKKKK00Oc. ...            ...'',,,..   .;cccclc,. ..,'..    .:kk0X0xlco    //
//    ...',;;,,;;. ..    ...''......'''',;;:ldO0KKKKKKKKKKKKK0Oc..;;'.                 ..',,'.    ......',,,,,.... .lOkkdllok0    //
//    '',;,,,;;'.          ..''........',;:ldk0KKKKKKKKKKKKK0Ok; .,;'.       ...           .,;.        .,:clll:,''...clclldkk0    //
//    ,,,,,,;,........       ..''......',;:oxOKKKKKKKKKKKKK0Oko. ....   ..,:llc:,'..        .,,.   .. .,'':odl:;,''...'x0kxOOO    //
//    ,,,;;,...,;:cc:,.       ..''.....'';:ldk0KKKKKKKKKK0Okko'        .:okOOkdlc;,'..    ..''.     ..,.. .,xkl:,''',''x0O0Oxd    //
//    ,,,;,. .,:col:;;'         ..'....'',;:odk00KKK0KK000Okl.        .lxkkOOkxoc:,,''.......      .''..    ,kkl;,''''.lOO0Odo    //
//    ',,,.  .;:lol:;,.          ..''....',;:ldkO00000Okkko,.        .:oodddddoc:;,''''.....     ..''..      c0xc:,''..;kO0Oxx    //
//    .,;'. .,:cooc:;'.            ..''.''',;:llodkkkkkdl;............:loxkkkxdoc:,,'''....    ..''.  ..     ,dc:::,'..'dOO0OO    //
//    .,,. .';:ldl:;,. .......      ..','',;:cllooolc:,..            .:oxkkkkxol:;,'''.       ..'..    .. .. 'l;::c:,,''o0OOOd    //
//    ','. .,:codc:;'. ..',,'..    .  ..'.....'.....                  .:ldxkkdoc;,''''.      ..'..       .   .:odxdl;,,'cOkoll    //
//    ,;,..';:ldoc;;.    ...     ..    ..'.            ..''.           .,ldxol:;,,''.       .'..          .   .,coo:,''';kkldx    //
//    ',,..,:codl:;,.           .    .....'..       ..,coddl;............';cc:,'...       ....    ..      ..     .',,,...dkodo    //
//    ....';:cdoc;;'.          .     .;;:'.'........'::codolo;.      .....''.            .'..      ..      ..       ... .lxodo    //
//    ...';::ldo:;;'..        .    ..,::;,'',''.... .,cloool:.       ...  ...          ....         .       ..       ..  ;kxod    //
//    l;',;:codl:,,.......   ..    ..',::;,'......    .,,;;'...........      .,'.     ....          ..    .;:,.      ... ,kKkx    //
//    00Oxdolooc;;'.  ........    ..'''::;;;'. .................    ...    .;kOo;.......  .,'.       .   'lc,,,.     ....'xX0O    //
//    ooxkO0OOxo:;.      ....'.......',;,;;,,,. .''.                ..     .;xdc,......  .:ol:,.     ...;lcc;',.  ........o0Ok    //
//    lcloodxxOOOkl.  ..;::. ....... .'''''..'................................''..... .. .llcc:;;;::cloxkocc;,;'..........c0Ok    //
//    kollclccoodk0l. .:lodc.    ......'''.......  .'.........................  .::... ...ll:c:oO0Okkxxdoodl:;c;..........ckxd    //
//    00Oxolc:clloko...';:;.    ......;;;;... ... ..................'...........ckd;......,clokOOkxo:;c:;dOkl,;lc,.......'lOkx    //
//    oxO00kolcclodl'. ....    .......,',;....  ...................''............''........cO0kdkkkxl;ll;cll:,'co,......'':OKO    //
//    ;:lxO0Odlllodc''.  . ......''....'... .......................''.....................;kKOxodddoool::cc::::c:......''.,kK0    //
//    .,;:ok0Odolod:.'..   ..'...'....',.. ........................',.....................c0KOkxkxdolc::,''',:;'......''..;xKk    //
//      .,:lk00dloo;','........''....','...........................,;.....................':ooddddolc;;:,..',............''o0x    //
//       .,:lk0Oodo;''''...''.....''.''''..........................;:'..'..........';;'.......'odllc:;,,'',c,............'.c0k    //
//        .;:dO0ddo,'''''...,'...,,...........................',;::lo:;;,'......,:clol,......:dkkxdlc:;;,;:cc:,..''......''cO0    //
//    .   .,;lk0xdl'.'',''....'',;;:clooc,.....''............':odllloodoc;......:llooo;.',.,dKX0kkdlc::;;;,;:oo;''.......'';kK    //
//    ..  .,;cx0kdc'''',,''.........';cdOk:..................'coc;,;cclol:......;llooo;....c0XKK00Okdolc:;,';clc,........',,dK    //
//     .. .,;lk0xdc''''',,'''........';:oOO:..................;llccloolol;......',,;;;'...'kX0OOOOOOOkkxxoc;;:cc,.....''',''oK    //
//    .  ..,:oO0xo:','',,,,,'''.....'',;:oOk;.................';ccllolc:;'''..............'xXKkoccoxxddolc:;,,,::'...'''''',l0    //
//    ....';cx0Odo;''''',,,,''''.''.',',:cdOk:...........'....'',,,;:;,,''''''............:0KOd:,,:dxxxdlcc;,,;;:;'',,,,'''':O    //
//     ..',:dOKkol;''','.',,,,''''....',;:lx0k,...........'''','''',,''',,,'.............,kXOo:,,';dOxddl::;';;.,c;',,,,,,'';k    //
//    ..';cdOKkolc:;;,,''',,,'',;;;'..',;:clx0x,.''.''''',,'',''.'''''''','''''..........;OXx:;c:,,lOOdllc:;,:'.'c:,,,',,''',x    //
//    ',:lx00koc::;:c;,,,,,,,,,;;cl:..',;::cok0x;',,',,,;;,,''''''''''''',,,;,,'''...','.:00o;;dkl::oxkdc:,,:c:'.,c;'',''''''o    //
//    :ldOK0xlc:;,,;:,',::::::l:,:lc'.',;::clok0k:,;;;;;;;;;;;;;;;::;;;;;;;;;;,,,,,';dd:,cO0o:;xK0kxocclc:,';lol;.;c,''''''''o    //
//    xO00kdlc:,'',......'''.',;,;:c,..',;,;cldk0kc;;;;;;;;;;::;cdxddl;;;;;;;;;;;;;:xOxl;ckKx::kXKOxxoc;,''',coo:,'::''''''''l    //
//    0Okxdxl,,'.,,....';:;'..',:llcc:;:,'',:lodk0koolc;;;;;;:::dkxdxd:;;;;:::;;;;;clolc::xKOl;cx00xlc:;,,''';coc;'':;,''''',o    //
//    kxkkkko,.';;.....,oxxl'..;clc:lo::::;;;,:ldxkxxdl:;;;:::;lOkdodxl;;;;::cc:::::::c:;:ck0d:,;oOOo:,'''''':c:lc;,,c:,,',;:d    //
//    kkkkkko;.;:. ......',,...',:::oo:;;;:c:::cclloxxxdc;;::::ldollllc;;;:::::::::;;;:;;;;lxdc;,:okxc;''....,,;lc:;,,::;;cxO0    //
//    kkkdolc;;:,..............',;:clc:;;;;;;;;:::ccoxKXOl;:;;;:;;;;:::ccc:::;;::::;;;;;;;;:cccccclxd:,:oo,...,coo:;,,;::cx00O    //
//    oolccc:;'.  .............''';oxxxxxdddddddddxxkO0Odc;;;;;;;:clllccc:;;;;;:cclloddxxkkOO0000OOOd;:x0Oo,..,:ll:;;;;;:oO0OO    //
//    ;;,'...            . ......';okkkOOOOOOOOOOkkxdolc::;;;;:coxxocccc::codxkOO00KKK00OOOOkxOXK0Oo::looloc,'';c:;;;;;:ck0OOk    //
//    ......               ....',,:dxlllcccccc:::::::::cclodddxxxdoloxxook0KKK0OOkxddoolllccco0KOko:;c:::;cl:,,:c::::;:;codxxx    //
//    ......            .....',,;:ok00OOOOkkkkkkkkkkOOO0000Oxkkxodxddxk0KXXKkdolccc::::;;;;;:x0kdo:;:c:::;co:;;:c::;;;;;;;::lo    //
//    .......          .....',;:codddddxkkkkkkOOOOOkkkkxxddlldddllooollkXXX0dc:;;;;;;;;;;;;;:x0xoc:c::;;;;coc;;ccccclllodxxkOK    //
//    ......          ....'',;:coO0kdolccccccccccccccc::c::cc:::ccc::::okOKXK0kxxdolllllcccccoOOdcclllllooddc;lk0000KKKXXKKKK0    //
//    ......         ....',;:;;lxk00KK0Oxdoc:;;;;:;;;;;:;;:::;;;::::::::codkkO00KKKKKKKKK0000O0Oo:cx0KKKKXKk:;dO0OOOOOkkxxdool    //
//    ......         ...',;,',coloddxkO0KKK0Okdoc;;;::ccccc;;:;,,,,;;:::;:cclloddxxxkkkOOOOO00Oko,:xOOOkkkxd:,cllc::;;,,'''...    //
//    ......        ...';;..'cl:::ccloddxxkO0KKK0Oxxdoc::;:;,::,,;;;:::cc::;::::ccclllllllloollox:,::::;;;,;;',,;::;'........'    //
//    .....         ..':;...;l:;;;;:::cloodddxkO0KKXXKOkxddoccc:;;;::;;;;::::::::::::;;;;;::;,';dd:;'............''.........;d    //
//    .....        ..':c;...;l:;;;;;;;;;::clooddddxkO0KKXXXK0OOxdool:;;;;;,,,;;;;;;:::;;;;;;;;,;ooc;,.......................:x    //
//    ....         ..;l:;'..,cc;;;,;;;;;;;;;::cloodddddxkOO0KKXXXXXK0OOkxxdoolc::;;;;;;;;;;;;;;;,'''.....................''',;    //
//    .........'.  .'cc;;;...;:'....,;;;;;;;;;;;::clloodddddxxkkO000KKKXXXXXXKK00OOkkxxdddoollllcc::;;;;;;;;::::ccccclllloodxx    //
//    ....'',,;;,. .'cc;;;,...;;,,,;;;;;;;;;;;;;;;;;;::cclloooddddddxxkkkOO000KKKKXXXXXXXXXXKKKKKKK00000000000KKKKKKKKXXXXXXXX    //
//    ........','. ..,::;;;'.....',;;;;;;;;;;;;;;;;;,;;;;;;:ccloddddoooooodddxxkkOO0000KKKKKKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXK    //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract EODI is ERC721Creator {
    constructor() ERC721Creator("Exploration of the Digital Imagination", "EODI") {}
}