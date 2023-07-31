// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BodyArt
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    00000OOOOOOOOO0OOOOkkkOOOOOOOOOOOO0000000000OOOOOOOOOOOOkkOOOkkkkkkkkkkkkkkkkxxxxxkkkkkkxxxxkkkkkkkO    //
//    00Oxoooolllodllcccl:;;;::::;;;;;,;lxdddodxxxxxxxddxxxxxdxxxxxdddddddddddddooddooodxxxxxxxddxkkkkkkkk    //
//    00kc:::::;;;,'',,;,.........'''....':llclllllooooodooooloooddoddddddooooddololoodkxxxxxxxdodxxxkkkkk    //
//    00Ol;;::::;'.'...........';cc:,......;lccllllcllccllllclllooddddddddooooooooolldxkxxxxxxxxxxkkkkkkkk    //
//    0OOo;;::::;'........,;;,:lxkkkx:.......,cloolccllllllllclloddddooooooooddooddoodxxxxxxxkkkkkkOOkxxkk    //
//    OOko;;:::;'........'''..'',;:;;,,,'',,'';cooolooooddddlloooooooooodxdoddddodoodxdxxxxkOO0OOOOOkOkxkk    //
//    Okxo::,'.......;llcc:...''';clcoxdolooollloolcloooooodoccooooddoloxxxdddooddooddoddxkkOOOkkOOxxxxdkO    //
//    Okxd:....,;;:cokkOOkc',cc:lddxdxkxddxkxdollllloooolodooc:cooooooodxxxdoddddxddollloxkkxxkkxkOkkdoxkO    //
//    00Ol'..;cdxxddxkkOkc.'ll:codxxxxxxdxkkkdooodxxddoooddoooolccllllloooooddxdxxdddoloodxxdodxxkkkkkxxkk    //
//    0Okl..:ooxkxodxxxkc.,::cllldxxkkkkxkOOkkxkkkkkxxxxxxdddddoc;,,,,:clllloddddxdxxxxkxxdodoodoloddxxxOO    //
//    00kc..lxxkxl:ldoll;,;:cccldxxxkkOOOOOOkkkkkkkkkkkkkkxxxdolc;,,''',;:llooloddxxxxkxxxddxdooolcloooxkO    //
//    00Oc.;odxOd;;c:;::,;:clooodxkkkOOOOOOOkxkkkkOOOOkkkkOkxxdoll:;,',,..,coolodxxxxxxdxxxxkxxdoooodxkkkk    //
//    00Oc,ldxkkd,';',:;;;;:oxxxkOOO0000OOOOOkkkkOOkxkkkkkkkkxddxdol:;,,,...;lllddodxxxxxxxxxkkkkxxkkOkkOO    //
//    00Ol,cddkxxdoc,,,':lloxkkO000OOO000OOOOOOOOOOkxxxkOOOkkkxxkxxdol:,,,''.,:looodxdddxxxxkkkOOxkOO00OOO    //
//    00Ol:cldkxxdool,.'cdodxkOOO0OOOOO0000OOOOOOOOOkxkkOkkkOkkkkkxxdo:;;;:;;;':lloooddddxxxxkOOOOO0KK0OOO    //
//    0OOxlc;:oxl;loll;'coooddkOOOOOOOO0000OOOOOOOOkkxxxxxkkkkkkkkkxdlc;;;,,;c;;llloddddddxkkkO00K0OO0OkOk    //
//    0OOOko:;coc,ld:cl,;llcldkOOOOOOOO00OOOkOOOOOkxxxkkkkkkkkOkkOOkxdoc:::;.':c:cccdxxkxxkkO0KK00OOkOkxkk    //
//    00Oxdkd:;dxc;;:lc',cllodkkkOOkkkkkxdxddxkOOOkxxdxkOOOOOOOOOOOkkkxl:::;'..,:,..,lxkkkkO0000OO0OOOOxkk    //
//    000kooxo;lkdlcco:..,coodxkkkkkkxoc::ccodkOOkkkxdodxxkkkkOOOkkkkkkxdocc;,..':,..,lxkkkOOOOOOOO0OOxxkk    //
//    0000dlxd::dlcddl:'.';clodxOOOkdl;'',,:oxxkOkxxxoodxdodkkOOkkkkkkkxdocllcc;.':;,,,cxkkkkOOOOOO00Oxxkk    //
//    000Oolxxc:doldocc;'';:::oxkkxdl:,.',',codxkkOOOxolcc:lxOOOkkOkkkxxddoddddo;.';''',cxkkkOOOOO000OkkkO    //
//    OO0kcoko:okdodlcc,';::;:loddoc:;..,,';:loxkOOOOOkoc;.,okkkkkkkkxxdddxxxxxoc'.,,'.';cdkkkOOO00OkkOOkO    //
//    OOOdlxxooxkdldooc'';:,,;:cllc;,,.';;,;:ldxkkOOOOOxdc;;coxxxxxxxxxddxxxxxxolc;',,,;;':xkkkO00kO000Okk    //
//    OOOxxkxlokklcddo:',;,'';:cc:;,,'.';;;:loxkOOOOkxOkxdlccldxkxkxxxxxxxxoooc:::;'',',;,'lkkOOO00O00Okkk    //
//    0OOOkkx::ddloxxl,;;''..';::;,,'..,,,;clodkOOOOkkOOOxolodkkkkkkxxddxdolcc;,;;,'.''.',';dkkOO00000Okkk    //
//    000OOkxolllcokd;,:;;:;,'',,;,'...,;,;cloodxkkkOOOkOkxdxkkOOkkkkkxxxolc;;;;;;,'.',..,,'cxOO0OOO000kkk    //
//    000OOkxocol:oxl,:c:ccc:,'.,,,'...;cccclooodxxkOOkkkkkkkkOOkkkkkkxxxolc:;:c:;,,,',,.',',oOOO0OO000kxk    //
//    000OOxlcoxl:od:;lc:ccc:,',;;''...':ll:clolldxkkOOOOOOOOkkkxxkkkkkxdool::cl:'.','';,';,,ckOkOOO000Oxk    //
//    000Okl:dxdl;ol,:llclcc:;,',,''...,;:c;,:cccodxkkOOOOOkkkkxxkkkkkkxdool::cc:'..''';;.,,.;xkkO00000Oxk    //
//    0000kc:ddlc:ol,clcllcc::;,''''..':;;c:,,;clddxxkkOOOkkxkkkkkkkkkkkxdoc;,,;;,'.....,.';.,xOO00000Okxk    //
//    0000kccddlcoo:,cc:looolcc;'.....,;,',;;,:loddodxkkkkkkkkkkOkkkkkxxdooc,..',,'.....''.,',dOOOO000Okxk    //
//    00O0kloxxc:xo;,cllodxddl:,......,...';:clllooddxxkkkkkOOkkkkkkxxdooll:,'.','...........'d0OOkkO0Okkk    //
//    0OOOxooxo;ckl,;cloooxxddc'... .....',:c:::loddoodxxkkkkkkkkkxxddooolc;'''''............'oOOOOOOOkxxk    //
//    0OOOkxdxc;oxc;ccloodxxdo:'.....''',;,,:llodddodxddxkkxkkkxxxxddddddoc:;,,'''''.........'ckOOkOO0Okxk    //
//    00OOkkxdclxdc;cllodxxdol:''...',:cc;'';codddooxxdxkkkkkkxxxxdxxxxxxdolc::,''.......'...'lOkkkO000Okk    //
//    0OOOOkkocoxx:,:llodxkxdl:,'..';:lddl;,,,:looodxxxxkkkkkkxxxxxkxdddool:;;,'''.......''..,ckOOOOOOOxxx    //
//    0OOOkkdclxkd:;clodxkkxol:,'..':ldxkxdc,,:lodxxxkkkkkkkkkkkxddddololc:,,'',;,.......,...':k0OO00Okxdx    //
//    OOOOOkl:dkOo;:cldxkOkdol:,'..'cdkkkkko;;ccldxxkkkkkkkkkkkxdollllllc:,,'.',.........;'...lO0000Okkxxx    //
//    OOOOOx:cxkOo,:odxkkOkdoc:;..,,cxkkkkxl;;;:oxxxxkkkkkkkkxxxddolllcc::::;'...........;,...lkOOOOkkkxxk    //
//    OOOOOd:coxko;:oxkkkkdol::,.':::loxkdl;,loodddxkkkkkkkkkkxxolllccc:;;;,'....'.......,,,';oxxkOOOOOkxk    //
//    OOOkko;:lxkl,:dkkkkkxol:;'..:loocod:,''colddxkkkkkkkkxxxxxdollcc:'.''.''.''.......',;;;:odxO0O0KOkxk    //
//    OOOOkd:;cdOo;cxkkkOkxdc,'....';:;:cclc,,:coxkOkkkkkkxxxxxxxdddoll:'.',;,..........,,';;;dkkO0O0K0kxk    //
//    OOOOkkdc;okd:cdxkkOkdl:,'.. ...'';dkd:.,:ldkkkkkkkkkxdloollooodolc;,'',,..........;,';;cxxkO0000OOkk    //
//    OOOOkkkocdkd:cxxkOkxdl:;;,....';:cl:'..,:lxxxxxxdlll:col;''',clolc:;'............,;',';dkxkO0000Okkk    //
//    0OOOkxxddxxdccdxkOkxdl:;cc,,;;cdxoc,..,;:lddolc:;:c:,:xd;''':llllc;.....'''.... .,,,;;lkOOOOO0Okkkkk    //
//    0OOOOkkkkkkkl;cdkOOkoc,.;c:llcokkc,,..,:::::;'':oxxdc,,,,;codollc:'.....'''.....';'',cdkOOOkxxxxxxkk    //
//    0OOOOkkkkkOOx::oxxxo;',;looooolc:;;;'.',,,:llc;;:;''.';coddooccc:;,.............,,,,;lddxkkOkkOOkkxk    //
//    OOOOkkkkkkOOkl:dkxc;;;coodoll::cloooc;,:loxxo:'..,;:cllloocll,;c;,,'............,',;oddxkkkOkdddodxk    //
//    OOOkkkOOOOOOOxooo:..,:lolclxo:codxxdddodddoc,..,clllc:clol;,,'''';;,...........''';ldkxxxkOOxoooloxk    //
//    OOOkkkkOOOOkOOkkkxdxkkkkdoxxoccodxdoll:;:llooccllcc;,,;;,'....,,,,'............,,':odkxxkkOkxxdoodkk    //
//    OOOOOOkOOkkkOOOkOOkkOOxoool:;,,;;;;:;,,:okxl:;;::,,'..''....';c:;;'...........',',cddxxkOOOO00Oxdxkk    //
//    OOOOkkxkkxkkkkkkkkkkOxoloc;;,'.',;:clcclooc,'.'''....,:c:,.',;:::;'...... ....',';oxddxxkO00Okkkxxkk    //
//    OOOxdddxxdxkkkkkkkkkkxcclllolc::::cllllc;,';:ccllcc;,,;;:;'',,;;'........ .,:,'..;oooooxOOOOkxxddxkk    //
//    OOOkdddxxdxxxkkOOkkkkkdcloxkkkkxxdxdddddddddkkkxddol::cclccoc,,:ccc:::::;;cllc;;;coddxdxkkkkkkkkkkkk    //
//    OOOOOOOOOOOOOOOOOOOOOOOOO0OOOOOOOOOOOO000000OOOOOOOOOOOOOOkkkkkkOOkkkkkkkkdodxxxxxxxkkkkkkkOOkkkkkkk    //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SBNFT is ERC721Creator {
    constructor() ERC721Creator("BodyArt", "SBNFT") {}
}