// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: UnderCurrents
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                    //
//                                                                                                                                    //
//                                                                                                                                    //
//                                                                                                                                    //
//                                                                                                                                    //
//                                                                             .....                                                  //
//                                                                      .  .,::;,,;;,'..                                              //
//                                                                    ....,odl:,...',:dOo.                                            //
//                                                                    .. .lkdl:,'.',:::od;                                            //
//                                                                       .;:;:c;,'';::,,;;.                                           //
//                                                                       .,'..','''',,'.','.                                          //
//                                                                       .''.............,...                                         //
//                                                                        .................                                           //
//                                                                          ...............                                           //
//                                                                           .....   ....''.                                          //
//                                                                         ......      ..;:.                                          //
//                                                                           ...  ........:;.                                         //
//                                                                           .'...........';:;;;;,....                                //
//                                                                        ..';:,'........,:oxOkxo:,ckkkd'. ....                       //
//                                                                     ..,:dkOxolc;;;:cloxkOkdl:,',lOOK0:',;:c::c:'                   //
//                                                                 ':ldd:,;:ldxkkkxxkOOkkdol:,'''''cOOOk;.'...',:dkc.                 //
//                                                 .'...        .;lOXXKOl,,,,,;:cllllc::;,''''''''',dOkOd;,'...';cxOo.                //
//                                                :xo:,'''.  .';cdkO0K0Oo,,,,,,,'''''''''''''''''''':kOkOl,...'',;:loc,.              //
//        .                                      .:ll;.';;';lloolllox00Od;,',,'''''''''''''''''''''',:kkkO:....',,,,;codo,            //
//                                              .;:c:'.,;codolcccccloO0kd;',',,,'''''''''''''''''''',,:xkkx' ...,;,,,;:lxxc....       //
//                                              ;xo::;;:ldoc;;;;;;;:lk0kd;',,,,,,,''''''''''''''''',,,,:xkd;.....',;,,,,;col;....     //
//                                              ,c;,;:;:ll:,,'''''':lk0kx;'',,'',,,,'''',''''''''''',''';ol,.......',,,''',:ol,.      //
//                                              .;'',;;:loc;,''.',;ldO0Ox;'''',,,,,,,''',:cllc,'':lc,'',',,.... ......'''''',ox,      //
//          ..        .',,,'..                  .;:;;,,:odl:,,'..',oO0OOo,,''''',:loooc,:xOOOkc';dxdc';odo:,...   ......''''';oc.     //
//                    .;::;,,'....               .'...,ldoc;;,....'o0Okkc''',;::;lkO00Ol;oO00Oo;oxdd:,clxOl:'..'.    .........,,.     //
//                   ..''......,;,..      ..  ..,c;..,oxoc::;,.. ..o0kxd;'';oxOOdcok00Od;ck00Oxoxkkxc:dooo:'...::.     ..........     //
//                         .....,'.        .'coxOd:;lxkolcc:;'.. .:okxdl:llcdO0K0xodk00kddkOOOkkkOkxxdkxlc,....':;.    ..........     //
//                          .          .,:ldkOOkl.'lxxolcccc;'..;dkxdddodO0kodk000Okkkkxxollcc::clllooxkd:......',.    ...........    //
//    ...                             ,xxxOkkO0k;.;odoolcccc;'':dxdoddl,,cdO0OkOOOkxl:;,,''''',,;:cloddo:'.........     ..........    //
//    ...                   ...      .:oldkO0O0Oocldoollccc:,,lxxo;:lc,''',ck00Ool:;,;:;,'''';odollc;;:oxl.........      .......'.    //
//    ...             .....'ll.      .::cdkO0OOOOkkdolcccc:,;oOOxc,'''''''':xkxddddddddxxo:,;dl'. .... .cx;........      ......''.    //
//    ....         .. ..',cdl.      .,:;cxO0000OOOxolccccc;;oO0kxl,'.''''''',:dko:,'....:kOcld' .:xxkd. 'dl........       .....'..    //
//    ...         ......,ldl'      .';c;cxO0koxOxdolccccc:,,cdxxdo:;,''''''',oO:. .:cl:. ;OdcdoclkOldOc .cx;.......       ....''.     //
//    ..         .......cdc.        .'::,ck0ocxdlllccccc:,,'',,;ldoc:;'''''',ok;.'xKk0k' .dO::oollkkxd; .oO:........ ..  ....'''      //
//    ,'.      ....   .:o:....       .c;'.cdldxoc;,;;;,,,'''''....''',,,''''';xxdddkOk:..:kx;'''';kx'....;xd;........... ....''..     //
//    ;,..   .....   .co,..''..      ,;''..'cdddc;,,'''''''''''..,cllc,'','''',;;,cko. .oOd;'',,,,lkxoko. ,xo'..............'''...    //
//    ,.....''''.  .'lo,  ...'..    .;,''...;odkko:,,,,'''',;ccldxxkOx;..,,''''';okc. 'dkc,,;,,:lod00dx0c .ok:''''........',;,'...    //
//    ''...';clolccloo;.   ....   ...,''''..,x0OOo;;;,:oollodxkkkOkxxd:...'','':xk:..:kOkxxxOd:x0dclOOxx;  :Ol'''''','.. .':c:'...    //
//    ;,,,cdxdooddxxoc;,...,,.. ..,'''..''...l0KO,'xO;'kN0kOkkkkkxkkkd;....''''l0l..cK000o,;k0cd0l...... .,dd;''''''.. ....;cc,. .    //
//    ::lOK0dl::cooolcc:;;llc:;;;:;..........ck00o',:.'kNKOOOOkkkkxkkd;....''''cOo. ':c:,...o0o:dkd:'.'',;cc,..'',;;;'..,,.,:l:...    //
//    ;lkOkdllc::clolcc:;:llc::::::;........,lkOKx',o:.oNXOOOOOkkkxxxd:'''''''';kx,.,,;:cloodxc,,,::,,'''''',,,,;cclc;'.,;;;:c:;;;    //
//    ,odoolllccccllcclc:;;:::::::::;'......,okOOOl:ol.cXXOkkkkkxxddxdl:;,'''''':ollllllcc:;,,''',;;clodxkkOOkxc;;;:c:,,,,,,;;;:cl    //
//    ,clc::;::;;;:::ccc::::::::::;;;,'''',':xkxool;'.,dK0Okkkkkkxdolc:;:dxddddddddddddxxxxkxxkkOO0KK0Okkdolc:,',...',;;'.';:c:;,'    //
//    ':oc;;::cccccccccclc;,'...'''...'lk00xxOkl;:;,,,,,:cllllllc:;;,,,;:ldddxxxxkkkkkkkkkOkkkxdollcc;,,''''''''''.   ....',;cc;,.    //
//    :colccc::::cccclllc:;,'.. ..   .dNMMXkkOOxol:;;;,,,,,,,,,;;;;;;;;;,'',,,,,,,,,,,,,,,,,,,,,'','',''''''''''''......',''','',.    //
//    lcloolcccccccccllc:;,,'.......,dNMMW0xkO0Ododdoc;:::::cccc:::::::;,'',,,,,,,,',,,,,,,,,,,,'''''''''''''''.'''',',cdxddxo,.'.    //
//    lllddoolllclllcc:;;:;,...',;clodxkOkdxkxxkOOkdddkkxxxkkxxxdolooddc,'',,''''''''',,,'''''''''''''''''''''''''',,,;cllolodc,'.    //
//    codolll::cdxdo:,',cxkxddxkOOxlccc:,';okOxkkOO00OOOOkkkkkxdxxxkOOkl,'',''''''''''''''''''''''''''''''''''''''',,;cooooloddc;.    //
//    lddollc;cdO00xlcoOXWMMMMWWNNx;;::;'.;lO0OOOOkkkkkOkkkkkkxoc:;;;;,,''',''''''''''''''''''''''''''''''''''''''''',coolcloddc''    //
//    oollllcldxkO00KNWMMMWWWNXXXKo..',,'':oxkxxxxdddddodxxxxoc;,,,;:cc;''','''''''''''''''''''''''''''''''''''''''''':lollllol'.'    //
//    ccc:;::lk0KXWMMMMMWNXNXKKXXXk;.....'lxkxdddddddddddxxxxkkkOOO00Kk:''','''''''''''''''''''''''''''''''''''''''',ldollccclc'.;    //
//    ;:;:dkOKNWMMMMMMWNXKKKKKKKKK0d;...';okOkxkkkOOOOkkOOOOOkO0000O00k:'''''''''''''''''''''''''''''''''''''''''''',dOkxkxxxxol:,    //
//    :::oXMWWWWMMMMMWNK0OO000KKKK0Oxlcxxld0KKKK000000OOOOOO0OkO0000OOx:''''''''''''''.'''''''..'''''''..''''''''''''ckkxddxxxxxo,    //
//    llc:dXWWWWMMWWNK0OkkO00000000OO0XXxoOKXK00OOOO0000OkOO00OkO00000d;'''''''''''.''..'''''.....''''''..''''''''''';odoclolldxl'    //
//    :;'..lKNNWWWXKOkxddxO0OOOOOOOOOKN0od0XKK0OOOOOOOO00kxO0OOOOO0000d;''''''''''''.'''...........''''.....'',''''';lddolcclloo:'    //
//    ..   .;xKXNKkxkOkxxOOOOOOOOOOkdxOdlx0XKK0OOOOOOOOO00kxkOOkkOO000d:'''''''''''''''''''..........''.....''',''',dXKxol:;clc;..    //
//          .xKXX0xdxkkkkOOOkkkkkkxoccccdOKKK0000000O00OOOOkxkOOOO0000kc,'''''''''''''''''''............''..''','',cOWXxlc;,;cc,      //
//          ;KWWNKxoddxkkkOkkkkkkkxdoloO0OxdollooxO0000OOOOOOxxOOOO00KXx;'''''''''''''''''''''..........'''''''',',o0Kkolc;;:ox:.     //
//          .:xOOkxdoddxxkkkxxxkkxdoooddddo:;,,,,:oxO00000OO0OxkOOO00KWKl'''''''''''''''''''''..........'''''''''',oOo,,::;::oo,..    //
//           .....,,:cllllooooddxdolccloool:;,,;:odlok00000000OkkOO00KNXOl,''''''''''''''''''''..........''''''''';xKd;,',;:;;,.      //
//          ..       ......'';::llc:;::cllc:;;cloddddkOOOO00000OOO00kxkKX0c''''''''''''''''''''','........'''''''',dXKOx:,;;;,'..     //
//    .    ...        .,lc,,oOd;''.....,loc;,,:loodo:;;;:lxkOOO0O00dl:ckXKc'''''''''''''''''''''''.........''''''',l0NXd'.....        //
//    .     ....      'lo:..ckkc''..   'll;;:;,codl,.  . .codkkOO00dccdXNk;'''''''''''''''''''''..'::::cclooddl;''';dK0l,....         //
//           ........':c;..,coxd:.... .:c,,,;::lol;.     .:::ldxkOkxkOKNXd,,:;,,,''''''''''',;::,'';:ccllllcclllcccdkkOOko:'.         //
//    .      .........,'   .,;coo'    .::,',,;cc;..      .:c,,;::lodxdkXKl,ldolcllllllcc:;;lk0ko:;,;clllooddxddxdooookOllxl.          //
//    '     .:;.......'.     .,;lc.  .,;,'',,;:'.         ':;,,,;;:lddkKKd::cllooooodddxdddkkdddc,,;cdxc;;,,'..ckOkkOKOlldl'          //
//    .     .;;.......... ...',';ol. ,c;'',,;:,.          .,;'''',:lodxkO0kkxdodkkkxdddoooodxOKkc;;;;co;        ':lddl::cll;.....     //
//    .      ','.........  .',;,;lo;,cc;,;;;::.            .,'.',;:ccccllc,..  .':cldO0KKXXXOdl:;;;,,;:;'..   ....';:,.';cc,.....     //
//    :'.    .;;;,...   ......,;;:llcc:;;;;;cc.            .,,',;;:cc:cllc,....     ..,clxxo:::::;;;col;,'........',:,..':c'. .'.     //
//                                                                                                                                    //
//                                                                                                                                    //
//                                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract UNCR is ERC721Creator {
    constructor() ERC721Creator("UnderCurrents", "UNCR") {}
}