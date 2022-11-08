// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Kika Nicolela
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                        //
//                                                                                        //
//    dddodddddddddxkxkdoooooddddxOOkkOOOkkdlllccllc::;;'....'.......',:ldxkxxxxdc,cdo    //
//    dddddddddddxxkxdoooddddddddx0NKkddoddxxolccc:;,',;;,;::,'...,:clldxxxdlcc:,';odd    //
//    dodddddddxxddddoodddddddddddxkOkdlc:::ldxdl:;;,'.'...::'...;llodxkl;cc,',;;:lddd    //
//    dddddddxxdododdddddddddddddddoc:;;;::;:dOkdl:;;;,'..;:'..,:;'';:;c;.,;;:cloddddd    //
//    ddddddxxooodddddddddddddddddddoll:'',;:xKKOdlc:;,;;;;'..;:c;'',,;;::cclodddddddd    //
//    oddoddkxooddddddddddddddddddddo:cxkl'':kXXKkdollcc;'...,;;;;;;;;;::clddooooddddd    //
//    dooodddxxddooddddddddddddddddddc;:dl,,:ldk0koc:::,...''',''''',,;;:loddooooodddd    //
//    dddddddddxxxxxddddddddddddddddddoc;,',;:::;,...,'.',;,,,,,,,,,,;;:cldddooooddddd    //
//    ddddddddddddxkkkxoddddddddddddddddolc:;;;;:c:::;',::;,,,,,,,,;;;::coodoooooooood    //
//    dddddddddddddddkxooddddddxddddddddddddddddkkdlc;,:::;;;;;;;;;;;::cclc::looooddoo    //
//    oooodddoddddddddoodddddddxddddddddddddddxddkkol;;cc:::::::::::::::c;'',;:loodood    //
//    oooooooddoooooodddddddddddddddddddddddxkOdoOk:;;odc;cl:::;;;::;,,,:;',;,;:clolcc    //
//    ooooooooooodddddddddddddddddddddddddkOKOxx0Oc'':ko..c0d;,,'',,'''':lc:cllldxoc:c    //
//    oooooooodddddddddddddxkkOOOOOOOOOO0KXX00KKOl;,:kx,..cKXdll:',,,'..;cldollloloxdo    //
//    ooodoooddddddddddkO0KXXNXXXXXXXNNNNNXXXKOxl::o0k:''.lXNOxxc'';::'..,cxOdlcclodxk    //
//    ooooooooooodddxOKXX0Okxddooooodxk0XNNXOdoollkKk:,'',xWXOxxc..,loc...l00xddxxdddd    //
//    oooooooooodddOK0koccclodxxkkOOOOOKNNKxoddod0XOc,,'':0N0kkkl'..;xkl'.'lolcoxkOkdd    //
//    ooooooooodddO0d:;ldxkkkkkkkkOO0KNNN0xddooxKXOl;,,''lXXkxOko,'''cO0o;...';:ldxxxk    //
//    oooooooooodOOl,:xkxxddddddddddkKNKkxxdokKXXkc;,,'''dXOxkOko,'''':oo:.....';cldxx    //
//    oolooooooodOd,:xxddddddddddxOKXKkxxdllkXNXxc,,,''.:O0dkOOkl,''''''''.......';coo    //
//    oolooooooodkl'lxoddddddddk0XX0kxxdl:ckK0Od:,,'''';kOddkkkd:'.................,;:    //
//    ollooooooooxo,:doodddxk0KK0Oxxdoc:ldO0koc;,,'',:okxodxkxo:... ..................    //
//    ooloooooooodd:;oxxkO0KK0OkxdollloxOkxo:,,,,;codolcloddoc,......   .........',,'.    //
//    ooolloooodxkOkkO00K00OkxxxkxxxkOkxdl:,,'';oOko::clddlc,.....................;odc    //
//    oooollodk000OkxdoooloxOOOkkxdollc:;,'',cdO0d::loolc:,.....''''...............lOk    //
//    looodxOxddlc;;;;;;:oOOkoc:;;;;;;,,,'',oKXOc;cool:;'....''',,,'''.............;kk    //
//    loodkOx:''',,,,;:x0Od:,,;;;;;,,,,''',dKko:;lolc,'..'',,,,,,,,,,'''''........;odc    //
//    lloOOc'.,;;,''.,d0x:,,;:;,'.......',dKk:,;coc:;::::::::;;;;,,,,,,'''..''.':oxo;'    //
//    lokOc.':lllcc:;o0d;,;;;,''....'',;cxKk:;:cl::ldddooollcc::::::cc:,''..',cxxl;'',    //
//    ldOl.':loooooldOx;,;;,,;'..',;;cldkKOc,:cc::okkxxddoolooollooolc;,'..'cdxl;',,;:    //
//    lxx;.,clooooooOk:',;,;:'.,;:clodxkK0l,;:::;okkkxxddddddddoolc;,,''';lxxl;,,;::co    //
//    lxd'.;:looooodOd,,,,;c,.,:clodxxk0Kx;,;;;;lkkkkkxxdddoollccoooll::lkOo;,,;::cooc    //
//    ldd,.;::looooxOl',,,:c,,:loddxxxkK0c,;;,':xOxdxdddxdolclocldol:;cxOx:,,;::cllc,.    //
//    lldc..;:cooooxkc',,,cc;;codddxxxOKx,,,,,:okxoldxxxxdc;;:;,'....ckOo;,,:::clc,...    //
//    lllo:..';:loddkl''';ll:;codddxxx00l','':oxklcooool:;,........'l0kc,,;:::cc;....'    //
//    cllll:'....';:oo,'';lol::loddddxOk:''.,lxdocclloc,........'';d0x:,,;:::l:'...'''    //
//    cllllllc:,'....lc'',coodlllodoodOx,'..:lc:;:lodl,...',;;;:::d0x:',;;;cl;....''',    //
//    cccccclllllc:;';c:'',looxxxdollxOo''..,,';lll:''''';:cc:::cd0k:,,;;;:l;...'''',,    //
//    cccccllccllllllclo;'',lxdxkkdodxkl''..';ldxdc'.',;:::::,,;o0k:,,,;;:l:...',,,,;;    //
//    cccc:;,,,;ccllcccol;'';x0kkxodxkOo,,''';cdOkl'';;;,,,;:;;cO0l,',;;;cc'..',,;,;;:    //
//                                                                                        //
//                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////


contract KN is ERC721Creator {
    constructor() ERC721Creator("Kika Nicolela", "KN") {}
}