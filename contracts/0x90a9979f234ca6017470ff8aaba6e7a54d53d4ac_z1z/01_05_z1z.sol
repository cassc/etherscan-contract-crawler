// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: z1z
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    XXXXXXXXXXXXXXXXXXXXXXXXXXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK00KKKKKKKKKKKKKKKKKKKKKKKKKKKXKKKXKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXXXXXXXXXXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK00OOkkkkkkOOOO0000K0000000000000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXXXXXXXXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0Okxdolcc:;,,''''',,,;;::cllodxkO00000000000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXXXXXXXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0kxoc:;'..'',;;:cc,,:ccccc::;;,'..'',:codkO000000KK00KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXXXXXXXKKKKKXKKKKKKKKKKKKKKKKKKKKKK0kdl:,''''':lloxxkkkOkc:xOkOOOOOkkxo;;lc:;'..,;coxO0000000KKK0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXXXXXXXKKKKKKKKKKKKKKKKKKKKKKKK0Oxo:,.';:loxo;oOkOOOOOOOOl:xOOOOOOOOOOx;lOkOkxdl:;'.';cdk0K0000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXXXXXXXKKKKKKKKKKKKKKKKKKKKKKOdl;'';:ldkkOOOkcckO00OO00O0o;xOO00000OO0d;oOOOOOOOOko;,;'.,cok00K00KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXXXXXXXKKKKKKKKKKKKKKKKKKK0kl;'',,:xOOOkkOOO0o:d0O0000000d:dOO00000000o;dOOOOOOOOOo;lxdl;'.,cdO000KKKKKKKK0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXKKKXKKKKKKKKKKKKKKKKKKKOdc,.,:oko;oOOOOOO000k:cOO00000OOd;lkkkkOOOO00l:xOOOOOOOOOc;xOOOkdc,'';ok0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXKKKKKKKKKKKKKKKKKKKK00d:'';lxkOOkc:xOO00OO00Ol;oolllllllc,;llllllllll;,lxkO000O0x:lOOOOOOkxo:'.,lk0KK0KK0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXKKKKKKKKKKKKKKKKKKK0d:'';okOOOOOOx:lOOOOOxoll:,:lodxxkOOx:lOOOOOOkkkd;;lllllldxOo:xOOOOOOOOkl;;,.,lk0K00K00KKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXKKKKKKKKKKKKKKKKK0x:''';xOOOOOOOOOo:oxollcodkkccOOOOOOO0k:ckOOOOOOO0k:lkOOkxollc,;dkO00OOOOd;lkd:'.,oO00KK0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXKKKKKKKKKKKKKKK0Oo,',ldcckOOOOOOOOo;,codkOOOOOl:xOOOOO00OcckOO0OOO00x:oOOOOOOOOo,:ccoxOO00k:ckkkkd:'.:x0000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXKKKKKKKKKKKKK00k:''cxOOxclkOOOOxocll:oOOOOOOOOx:oOOO0O00OlckOOO00000d;dOOOOOOOkc:xkdocclxOl;xOOOkOkl,.,lO00KKKKKKK0KKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXKKKKKKKKKKKKK0d,',okOOO0x:lkkoccoxOOo:dOOOOOO0Occxdoollll:,clllllllo:,okOOOOO0x;okkOOOxlc:;oOOOOOOOkd;.':k00KKKKKK0KKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXKKKKKKKKKKKK0l,':dkOOOOO0x::ccdkOOO0OcckOOOkdoo:,cllooddxl:oxxdxxddo;,ccllodkOl:xOkOOOOOd;,cdOOOOOOko;;'.:x000000KKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXKKKKKKKKKKKOl'',lOOOOOOOOd:,ckOOOOOOOd:lolllloxd:lOkkkkkOo:dOkkOOOOkcckkxdlccc,:xOOOOOOOc:ddccdOOOOo;okl'.;x000000KKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXKKKXKKKKKKOl'':oclkOOOOxc:dd:lkOOOOOko:,:oxkOOOkl:xOkkkkOd:oOkkkkkOk:ckkkkkkkc,:ccdkOOOo;oOOko:lkOo:okOOo'.;x000000KKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXKKKKKKKKK0l,':xOxccxOOo:lkkOd:oOOkxlclo:ckOOkkOOd:dOkkkkOd:lkkkkkkOx:lkkkkkkxc:xxoc:cxx:ckOkOOkc:c:oOOOOOo,.;x000KKKK0KKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXKKKKKKKKKd,.:xOkOklcoc:dkkOkkd:odccoxkOd:okkkOkOx:lkkxxxxo;:odddxxxo;lxxxkxko;lxxkkdl:,;xOOOOOkkc.:kOkOOOkl'.:k00KKKK00KKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXKKKKKKKKk:.;dOOOOOOo';xkkkkOOkl,;okkkkkkl:dkkkxxd:,::;,,,''''''',,;,,:clodxxc:dxxxxxxl,;cdkkkOOo;c:ckOOOkko,.'lO0000K000KKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXKKKXKKK0l''lOOOOOOx:::cxkkOOkl:::okkkkkkx:cdoc;,''.''..','.',;,;;'.....',;::,cxxxxxxo;ldl:cdkko;oOx:ckOkko::;.,x00000KKK000KKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXKKKKK0Kx;.,:dkOOOx:ckxc:dkkd:cxxl:dkkkxxd:'''..........,:'.';;;::,.....'.....,:lodxo::dxxo::ol;okkOx:cxxc:dkl'.cO0000KKK000KKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXKKKKKK0l''ldccxOkc:xkkkl:oo:lkkxxl:okdc;,..............';'.';;;;,'.............',:l:;lxdxxxl,,oxkkkkd:;:cxkOx;.,x0000KKK000KKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXKKKKKKk:.;xOko:lc:dOkkkko,,okkkxxxl;:;..................,'..'',''.................'':odddxxc,,cxxkkkx:'ckkkOkc.'lO00000KK00KKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXKKKKKKd,'cOOOOxc'ckOkkkkl;:cdxxxxdc'.''.'........'..................................';loddc;lo;cxkkx:;::dOkkOo,.:k000000000KKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXKKKKK0o''oOOOOkc;:cxkkkl;oxl:oxdo;''''..........'oc...................................':oc;ldxo;lko;cxd;lkkkkl,.,x000000000KKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXKKKKK0l',dOkkOx;lkl:lxd;lxxxl:lc,''''............;dc....................................',cddxxc;::lxkx::xkdc:,.,d000000000KKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXKKKKKOc'':oxOOl;dOkxc:;:xxxxxl,''''''''..........'cxc....................................'coddxo,,lxxxxl;lc:lxc.'d0000000000KKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXKKKKKOc',ooclxc:xOkkkl';dxxxd:'''''''''...........:do:;...................................,cddl:;,lxxxxo;,cdkk:.,d0000000000KKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXKKKKK0l',dOxoc,:kOkkkl:c:cdd:'''''''''............'c:,c;...................................,c:;lo;:xxxo:':xkkx:.,d0000000000KKKKKKKKKKKKK    //
//    XXXXXXXXXXXKKKKKKK0o',oOOkx:,cdkOx::xdc::'''.....................::;c,...................................';ldd:;do::l;cxkkx;.,x0O00000000KKKKKKKKKKKKK    //
//    XXXXXXXXKKKKKKKKKKKd,'lOkOkccoccod;cxddl,..'......................;::c'..................................':oddc,::cdd::xkxl,.;k0O000000000KKKKKKKKKKKK    //
//    XXXXXXXXKKKKKKKKKKKk:':xOkkc:xkdl:'cxddc'..........................;clc'..................................,ldo:':dxxd;cdl:,''cO0O000000000KKKKKKKKKKKK    //
//    XXXXXXXXXXXKKKKKKKK0l',:loxl:xkkko,,cod:............................;dx:..................................'cc:,,oxdxo,,:cl:.,oOOO0000000000KKKKKKKKKKK    //
//    XXXXXXXXXXXXKKKKXK0Kx;':olc:;okkkx:;c::,.....,;,'....................;xx;..........................'',,'..',;c:;oxdo:,cdxo,.:xOO00000000000KKKKKKKKKKK    //
//    XXXXXXXXXXXXKKKKKKKK0l,,oOkd;;ldxkc;oo:'....';:::,,,,,,,,,,,,,,,,;,,;;cxd:;:cclc;..................,;;:,..';lo;:ooc;,:dkd:.'oOO000000000000KKKKKKKKKKK    //
//    XXXXXXXXXXXXKKKXKKKKKk:':xOOo;clclc;cxdc;:::codoolcccccccllllllooooooolldxdooddd:..................,,;:,..':oc,;::lc;lxxl'.ckOO0O00000000KKKKKKKKKKKKK    //
//    XXXXXXXXXXXXKKKKKKKKK0d,,ckOkcckxoc,;odc,,',';c:;;,,,,,'''''''''........:kkd:'.....................',,,'..'cl;,:ldd;:doc,.;dOOO000000000KKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXKKKKKKKKKOl,,:ldo:lkkko;,:,................................'lkkx:............................',,'cdodc,;:;'.,oOOOOO0000000KKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXXKKKKKKK00Ol,';ll:;oxkxc;::'.................................'';:'...........................,;,:ool:,;cl;',lkOOOO00000000KKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXXKKKKKKKK00Ol',lxdc;:lloc;l:................................................................':;;cc:,'cdo:''lkOOOOO00000000KKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXXKKKKKKKKK00kl,'cxxl;:lc:,,c;..............................................................';,';;:;,cdo;',lkOOOOO000000000KKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXXXKKKKKKKKK00Oo;':dxl:cxdl:,,..............................................................',,;clc;:lc,.,okOOOOOO00000000KKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXXXXXKKKKKKK000Od:',;c:';oxxl,''............................................................':lll,';;''':dOOOOOO0000000000KKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXXXXXXKKKKKKK000Okl,';cl:;;:cc;,..........................................................',:cc;,;c:,',lkOOOOO00000000000KKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXXXXXXKKKKKKKKK00OOd:',:do:,;::;'........................................................',;;,';lo:'':dkkOOOO00000000000KKK0KKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXXXXXXXKKKKKKK000000ko;',colc:ldoc;'....................................................';:;;;cl:,';okOOOO0000000000000KKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXXXXXXXXKKKKKKKK00000Oko;',:oo::lddl:'..............................................',;cc:;:cl:'.;lxOOOOO00000000000000KKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXXXXXXXXKKKKKKKK0000000Oko:'':llcccldoc,......................',,,'...............';ccc:;:::;'';lxkOOOOO0000000000000KKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXXXXXXXXKKKKKKKKK0000000OOOdc;',:lc::ccll:,'.................,;;;,,............',:cc:;:::;,',:oxkOOOOOO00000000000KKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXXXXXXXXKKKKKKKKKKK00000000OOkdc,',:ccccccccc;,'.............',,,,,'.......',;::;:::;;;'',:lxkkOOOO00000000000000KKKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXXXXXXXXXKKKKKKKKKKK00000000OOOOkdc;,',::;::c:::;;;,,''.......'',,'..'',,,,;;::;;;;,'',:lxkOOOOOO000000000000KKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXXXXXXXXXKKKKKKKKKKKK000000000OOOOOkdoc;,',;;;;;::::::;;,,,','..',,,;;;::;,,,;,,'',:ldxkkOOOOOO00000000000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXXXXXXXXXKKKKKKKKKKKK00KK00000000OOOOOOkxolc;,'',,;;,,,,,,;;;,''',,,,,,,,,''',:cldxkkkOOOO00000000000000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXXXXKXXKKKKKKKKKKKKKKKKKKK0000000000OOOOOOOOOkxdlcc:;;,,''''''...''',,;:clodxxkkkkkOOOOOO0000000000000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXXXKKKKKKKKKKKKKKKKKKKKK00000000000000000000OOOOOOOOOkkxxddddo:,:ddxxkkOOOOOOOOOOOOOOO00000000000000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXXXKKKKKKKKKKKKKKKKKKKKK00000000000000000000000000OOOOOOOOOkkkl'ckkOOOOOOOOOOOOOOOOOO00000000000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXXXKKKKKKKKKKKKKKKKKKKKK000000000000000000000000000000OOOOOOOOl,ckOOOOOOOOOOOOOOOOOOO00000000000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXXXKKKKKKKKKKKKKKKKKKKK00000000000000000000000000000OOOOOOkkkOl'cxOkkkOOOOOOOOOOOOOOOOO00000000000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXKKKKKKKKKKKKKKKKKKKKK00000000000000000000000000000OOOOOOOkxdxc,:odxkkkkkkkkOOOOOOOOOOOOO000000000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXKKKKKKKKKKKKKKKKKKKKK0000000000000000000000000000OOOOkxol:;,;'.';;,;:ldxxkkkkkOOOOOOOOOO0000000000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXKKKKKKKKKKKKKKKKKKKKK00000000000000000000000000OOOOkxl;,;:ccc;',:cc:;,,;ldxxkkkkkkOOOOOOO0000000000KK000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXKKKKKKKKKKKKKKKKKKKKK000000000000000000000000OOOOOkl,,:ol:;''....'';:cc,';lxxkkkkkkOOOOOOO00000000000000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXKKKKKXXKKKKKKKKKKKKKKKK0000000000000000000000OOOOx:';ol;'............':lc,'cdkkkkkkOOOOOOOO0000000000000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXKKKKKKKKKKKKKKKKKKKKKKK0000000000000000000OOOOOOkc.;ol,................,ll''lxkkkkkOOOOOOO00000000000000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXKKKKKKKKKKKKKKKKKKKKKKK00000000000000000OOOOOOOOx,.ld;..................;o:.,dkkkkkOOOOOO000000000000000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXKKKKKKKKKKKKKKKKKKKKKKK00000000000000000OO00OOOOd''oo'..................,ol.'okkkOOOOOOO000000000000000KKKKK0KKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXXKKKKKKKKKKKKKKKKKKKKK0000000000000000000000OOOOx,.ld,..................;oc.,dkkkOOOOOO0000000000000000KKKKK0KKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXXXKKKKKKKKKKKKKKKKKK000000000000000000000000OOOOkc.,ol,................'lo,.ckkOkOOOOO00000000000000000000KK0KKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXXXKKKKKKKKKKKKKKKKK0000000000000000O0000000000OOOk:.,oo;'.............;oo,.;xOkOOOOO000000000000000000000KKK0KKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXXXKKKKKKKKKKKKKKKKK000000000000000000000000000OOOOkl'':llc;'......';:lo:''cxOOOOOOO0000000000000000000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXXXXKKKKKKKKKKKKKKKK000000000000000000000000000000OOOxl,',:cllccccllcc;',:dkOOOOOO0000000000000KKK000000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXXXKKKKKKKKKKKKKKKKK0000000000000000000000000000000OO0Oxoc;,',,,,,,',;coxOOOOOO0000000000000000KKK000000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    XXXXXXXXXXXXXXXKKKKKKKKKKKK000KK000000000000000000000000000000000OOO0OkxdollllloxkOOOO0OOO00000000000000000KKK000000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract z1z is ERC721Creator {
    constructor() ERC721Creator("z1z", "z1z") {}
}