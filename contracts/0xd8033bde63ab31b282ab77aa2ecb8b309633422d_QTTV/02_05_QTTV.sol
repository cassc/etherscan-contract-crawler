// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Questions to the void
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                             //
//                                                                                                             //
//     d0OddOKK00000OO00000OOOO0OOOOOkxdo:,'...                           ...:oxkOOOOO00O00000000000OOkxk0k    //
//    o0xokK000K0OO00000000000OOOkkxo:'.                                     .:dkOOOOOOOOOOOOOOOOOOOO00kkx     //
//    oOod000K00O0000OOO000OOOOkkxo;.                                          .cxkOOOOkkOOOOO00000000OOkd     //
//    oxoOK000OO0000OOO000OOOOkdl,.                        ..                    'lxkkkkkkkxxxkkxxxxOO000k     //
//    ldx0000O00000O00000OOkkd:.                       ..........                 .,oxkkOOOO0000OOkxxxxkO0     //
//    lxO00OO000OOOOkkkkxxxxl'               ...    .......';,,'......              .:xkOOOOOOOO00000Okxxk     //
//    lk00OO0OkxxOOOOOOOkkd;.           ..'.. ...'. .;,. 'c;..',,,,'...              .;dkOOOOOOOkkO000OOOx     //
//    cO0kO0kdxO0000OOOkxo'           ... ..'.   .;,.....:;.,:,''''',,,'.              ;dkOO0000Okxk00O00O     //
//    lOkO0kxO000000OOOkl.           .';:,.  ';.  .::. .';,;:',;;,,,,,,'....           .;dkkOO0000OddO0000     //
//    lkOOxx0000OO00OOkl.          .,.,,':c'  ':.  ,l' .,,;:,:;'':loooooc:,..           .:xkOOOO000xcx0000     //
//    lO0xd00000O000Okd'          ..',,c' .;' .:,  .c, ..,:;:,,:ll:;;:::;;;,.            .okOOOOOO0xcx000O     //
//    l0koOK000000OOkx:.         .';,;,;l,..'. ;;. .:, .::,;;;cc:;;;:clllool,.            ;xkOOOOOklck000O     //
//    okox000000OOOOxo'        ',',::;c:,;..'..','.... ...,;;:lc:oo::::::::;;,.           .okOOOOxllxOOOOO     //
//    ddo000000OOOOOxl.        .c,,:ll;:cc;''...,;''..  ..'',::,;:::cc:;,;::;,,.           ;xkxddoxO0OOkkk     //
//    ood0000000OOOOxc.        ,:;,::colcl:...'';:;,,.  ..'',;,',cdOOOkoc;::::;.           .:odxO00OOOOOkk     //
//    olx0000000OOOOxc.        .;::,;::clo:...,:;;,,'.   ..'',;,lkxo::lxOocoo:,..           ;xkOOOOOOOOOOk     //
//    oox0000000OOOkdc.        .';cc:;:::c:'...;;'...      ...';dk:.  .:kd;::,,,.           'oxkkOOOOOOOkk     //
//    dxx0000000OOOkdc.         .,:cc:;'',,'....,'..       ...';okl...'lOo;::,,'.           'lxkkOOOOOOkxk     //
//    dOxO00000OOkkkdc.         .;cc:;;;;,.   .',,..      .';;;:coxxddxkxoc:,,;'.          .,lxkkxkkkkkkkO     //
//    o0kkO0OOOOOOOkdl,         ..;:;;::;,.   .,,,'.       '::cclcloddoccc:,;;;'.          .,:cc;.....',:o     //
//    l0OkkOOOOOkOkxoc'         ..',;;;::c:;',;;,,'..      .,;;::;;;:c::cll::c;..          ..:lo:              //
//    c00kxO0OOOOkkxl;.         .';cc:;;:c::::::;;;'.   .  ..':ooc:cllllccllc:;'.          .'lxkl....          //
//    :O0OkkO00OkkOd:,,.         .',,;;::cccc:cc:,'.    .  ..;cllcclooool:cc::;...     .....;oOOkxxxdoc;..     //
//    ,k00OkOOOOkkkdc:;....      .,;::cllccc:;;,,..        ..,:cc:;:ccclc;:ll:;:,'... .','',lO0OOOOOOOOOkd     //
//    'k0OOOkO0OOkkkl:,..''.    ..;:::ccccc:::;;'....  ......';cllcclloolccclccc;,,,'.',;,;lkO000OOOO0OOOO     //
//    ,kOO0OkOO0OkOkxc;'.','.  ..'::::colc:;;:::,''..  .....',;:cllc:::;;::lollc:::;;;;;;;:dOO000OOO000000     //
//    :kO00OOkO0OOkkkdc:,.........',;llllolcclc:;,;,'......',;;clcccclllllloolc::::;;;;:;:okOOOOOOOO000000     //
//    ckO00OOOkOOkkOkkxl:'..','. ...,::ooccc:::c:;:::;;,,;;;;;clol:c::lc:ccccccc::::;::::lkOOOOOOkkOOO000O     //
//    :O0OOkkkkkOOkOkkkkd:.';,,,....'':lccc::::c:clooclllloollllcccccclccccclccc:::cccc;:xOOOOOOOkxxkkOOOO     //
//    ;k0OkkOkkkkOOOOkkkOx:';::;,'..',;lc;,:lllcclcccllloooddxollc:clllc::ccc:::ccclc:,,oOOOOOOOOkxkkxkkOO     //
//    ,xkkkkkkkkkkOOOkkkOOkc',:::;,...',,,:ccc;;:ccllloxxollolclllcllccc::::::::cc;,'..:k00OOO000OxkOOkkkO     //
//    ;xxxkOOkkkkxodkkkkOOOkc..',;,,....,;;:clccccc;,;:::;:cl:';c:;;::ll::ccc::cc,....;xOOO0OOOOOOxk0OOOkx     //
//    ;kOOkkkkxkxc,;okkkOOOOkc'....'....''';::::::,.'cooolllllccccc:cclccccccc:c;....;dkO0OOOOOO0OxO0OOOOk     //
//    'k000OOOxdl;,:dkkOOOOOOkl,.......''.,;,'.,:cc:coddxdodddolcc:;;;:::ccc:cc;....,dOkkOOOOOOO0OkO0OOOOk     //
//    ,k00OOOOo;;;:dkxkkOOOOkkkxl:,.......,;:;,,;cllclooo:;lolc::::ccccccccccc;....;dOOOOOOOkkkOOOkk0OOOOO     //
//    :k00OOOko:;;lkkkkkkOOOOkOkxkxdc;.....',;;,:l:;:coooololooc::ccccccccccc;....:xOOO0OOO0OkxxkOkk0OOOOk     //
//    lxO0OOOkkkl:dOOkkOkkOOOOOOkkxxko'......''.,::ccccllc:;;::;::::::::cccc;....:xOOOkOOOO0000kdlok0OOOOk     //
//    okk0OOOOOOd:x0OOkkOOkkkOOOOOkkkd,.   .....';:;;;:ccccllc;,::::::ccc:;'....:xOOOOkkkO0OO000OxoclkOkkk     //
//    okkOOOOOOOxcd0OOOOOOkkkkOOOkkkOd;''.... ..,;:::cclllccccccccc:cccc:,.....;x0OOOOOkkkOOkO00OOkxc,lk00     //
//    dOkkkOOOOOkddO0OOOOkkkOkkkkkxxxoccc:,,;.. ..,;:;;:;;,,;,;:ccc:cccc:,....,dOO0000OOkkxkkxkOkxxddc';x0     //
//    dOkkOkkOOOkkkO0OO0OOxxOOkxxodkdc;;;ccc::;'';;;;:::ccc:ccccclccccllc;,'.'oOOOOOOO000Okxxxxdxddk00x,'d     //
//    dOOOOOOOOkkOkO0OOOOOkxdxxloolc:;;;clllc::ccllllccllllcclllcccccclc;,;,,cdkOOOOOOOOkkxxkkkkkxkO000k;'     //
//    oO0OOOOOOkkkkkOOkOOkkl:xkollclc;,;:lolllllllooolloddddddddlcccccc:;,,;:clloxxkkkOOkkOO00OOOxk00OOOk,     //
//    l00OOOO0OOOOOkxOkdxkd:lxdddoll:;::clollllllclooooooddxxxxoccccclc:;,',;::cclloodkOOO00OOO0OkkO000Okd     //
//    d0OOO00OOOxldd▓█████▄  ██▓ ███▄    █     ▄▄▄▄    █    ██  ██▀███   ███▄    █   ██████ O000kxOO0000Ok     //
//    xOkO0Okkddd:'l▒██▀ ██▌▓██▒ ██ ▀█   █    ▓█████▄  ██  ▓██▒▓██ ▒ ██▒ ██ ▀█   █ ▒██    ▒ddkOkkkO00OOOOO     //
//    xkxkxxkkdllxc.░██   █▌▒██▒▓██  ▀█ ██▒   ▒██▒ ▄██▓██  ▒██░▓██ ░▄█ ▒▓██  ▀█ ██▒░ ▓██▄  ooooodolokkOOOO     //
//    kxdxdololoccod░▓█▄   ▌░██░▓██▒  ▐▌██▒   ▒██░█▀  ▓▓█  ░██░▒██▀▀█▄  ▓██▒  ▐▌██▒  ▒   ██▒lccc:c:cxdokOO     //
//    xdccoodocloodd░▒████▓ ░██░▒██░   ▓██░   ░▓█  ▀█▓▒▒█████▓ ░██▓ ▒██▒▒██░   ▓██░▒██████▒▒xdodl:ldo::xOO     //
//    dc:xxllllccokO ▒▒▓  ▒ ░▓  ░ ▒░   ▒ ▒    ░▒▓███▀▒░▒▓▒ ▒ ▒ ░ ▒▓ ░▒▓░░ ▒░   ▒ ▒ ▒ ▒▓▒ ▒ ░ooccdxd;lOcckk     //
//    ,;OOcoxooxdodd ░ ▒  ▒  ▒ ░░ ░░   ░ ▒░   ▒░▒   ░ ░░▒░ ░ ░   ░▒ ░ ▒░░ ░░   ░ ▒░░ ░▒  ░ ░dollddxo:xd;dO     //
//    ,k0c:Ooc0X0dlcc░d▒l:;:c░dd░odoolcldddddd▒l▒llx00░00░xd;',d0K░xocc:░''░'..,;▒cll░olo░ddxolcccclc:do:d     //
//    ,d0l;dxooo:,:cclc░oxkOxc::░dddxxO0kdddodol░lclkK000kxdc;;ckK░dl:,░'..'.''';░ddlloxkxxollodoloodkOc,      //
//    c.,lolcol;lxxxxkdcccldxkOxlccloddllclddooollllx0K00Oxxdol:okxdoc:;,,,,''''.,clllx0OxoldO0kxkkOOxolld     //
//    ll:;;cl::odlclc:lddlccccldxdoddddkOkkxollllllldk0000kxxO0Oxdxdlc:,'',,,,'.,oO0OOkdolldxdddkkl::ldxo:     //
//    lcclo:,cl::dold:'':ldxdocccclodxxxxdooollllllldxk000kxdk0KOddocc;,,,,,,,'.,cclolccooo::kKxc;lxxl::lx     //
//    :xd,;kd':x;;x:c00ko:;:ldkkdoooolccloxkdlllllllodxk00Oxdx00kdoc::;'''',,,'';lccooolldl;xKd':ko,,cxO00     //
//    .o0d';kd'cd:locoxddxxdlcccodoccldkOkddllolllllldddxOOxodOOxxo:;;;,''','.':ddc;:cclcc,cOo,ld;.ck000Oo     //
//    ',oOd,'cl,';:llollc::lxkOxlccoxl;,;:lccolcccccldxddxkxooOkxxo:;;;..','..,ldolcccll::c::cdl',x000Ol'.     //
//    xc,:xkc.,ol,':llccoocccccoxxoclxkxxdl:odcc:;cccoxkxdddclxdxxdc,,,'.','..:olllllldxl;,;xx:;oO00Od, .;     //
//    O0Oo;lOx;.,;::ccllclodxoc:::oxdolcccoxdlocc:ccccokkkxl';odddd:'','.''''.;ldxkOOOko:';xl.:OK0Oo,..,oO     //
//    :x00kccxOxo;'oOc'dl.;::ldxdc;:oddxkdolooccccccccldxkko..cdddd;.',,,,;;,'cxOxocccc;;lko..d0xc. .ck00O     //
//    ..ck0Oo;cx0d.'kx'lk:lOd:;;clocccldoccolllc:ccccccoddxkc.,ooxd;..'',,,,',lxxdooloc:dx:':dOd. .:k00kl,     //
//    o'..cxOk:;xOo';dc:d:;xOkkdoc:clccooollloolccc::cloodxxx;,cdxd:..'''...'cooxxxdll,o0;.d0kl''cx0kd:. .     //
//    Okc. .ckk;.:xx:'cl;cc:odxkkkxoclxxxdxdddolllcc:coooodddo:lxxd:..''....':c;colloc,dk.,Od,;dOkd:...,lk     //
//    :xOxc. 'dko;,lxd;:l:cc:clooldxdoodooooolcloolcccodddoc:lxkdoo;.''',,..',::lllll:;kd.,kc.cc,..':lxOOk     //
//    ..cxOxc..lkOd:;lxc:c,:dxdollllldxxxddddxdoooolcllooddo:,;c::;..',;;,..',;ccclol;cOd.;k;..,:oxO0Odc,.     //
//    l'..ckOd'.'lkOxc;o:,cc:oolddolllloddddollodddocccccldkxo;..'''.';;,'...;coooloc:kO:.cd':O0Oxlc;...,c     //
//    Ox;. ;xOx;. ;xOOo:o;;xc;,.,ldoollooddllllodddoc:ccccoxxxdc'.',,,,''....'co:'.,;:kl.'xo.l0k:.  .,lxO0     //
//                                                                                                             //
//                                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract QTTV is ERC721Creator {
    constructor() ERC721Creator("Questions to the void", "QTTV") {}
}