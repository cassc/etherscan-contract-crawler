// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Love And Death Celebration
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    ''.',;,..',,'',,,;;;;;'.....',,'.....''.......'''.......,,...........''',;clodxOOO0OOkkkxdolcclooool    //
//    ,,,;:c:'..''',;,'',:cc;....','..'''..''...';;,,,,'''.''',;,.''.....'''',,:::;;okxkOOkkkxxollcclloooo    //
//    ,,:ccc:;,'.';ccc:;;:cc;'.,;:;'',;,,'',''',;:cc;''''',,,'.',,,,',;;,''';;,,;;ccokkkkxxxddolccclollloo    //
//    :cccoo:;;'.':d0K0dc:odl:cll::ccc:;,,,;,'',:::lc'.',:c;.,;:;,,,,:ll:,;lxd:'.;dkxxxddddoooolllccc::loo    //
//    looc:;....',';oxkdolokkdl:::lxocccc;,'....;lc,,,;loc;,,,,;;::,,:lc;;:ccc:;;lxxdoodddooxdoooccllclddl    //
//    c:,,;'....,:..';;,;ldOkc;locclcccc:;;,,..:xOkc.',:lc:ccllocclc;::,';;;'':lloxkkxdooddooolloc:clodxoc    //
//    ,;'':;'...','..;;,:ccx0d:cdol:;::coxoc;..:ldkl,,,:ccccokKXk:,;::c:;:ccl:'':loxxdoc:oddll:'',:;;clocc    //
//    ..,:l:''''';c:'..;c;ckKKd:;;,;ldolc;;,'',,:ol:lxkkxdooc;cxx:..',:c::cdxo:;:lllc::;,'';c:,'..,;;,,;:c    //
//    ::;,..':l:;:ccc:,,'.,cdxxc,:lloolclc:::::,'''';codddodc..,c:,,;::cc:,,;,........,::'',,..',..':::;;;    //
//    ;:,...',;,:cccc,..  .:d:;c,,olclkKXXKko,.  ...,;;:cllllc:ccc::::;;:c'   .',;c:;;;;,......';;'.,cll:;    //
//    :dxl::cc:,;:,'.....':ddc,''';;;okkOOkl.   ...';;:dkO0Oxc'';;,'...,:,.  ..;l::oc'..........',;:;,:cll    //
//    0XX0xdxdl:,'.....':lxxxkd:::;',:::l:..    ....'':x00KK0o:lxkko,.'.   ..  ...''.........';:;,;::..:od    //
//    XNNNKdoxkxc'.';:;cxkkkOKKkxlcc;;:;.      ....';ldxkxdodddoooc;,,'.   ..    ............'od;'....';:c    //
//    oxOkd;..:odl:c:;:oxooOKOdc::ccllc;.   .'''';okOOdc;'..'cddl;'..,'.      .'. .;llc,......,ol;'',;;'';    //
//    ;::;:lc:c:;'...,lllddlc,''''',;:::;...':cloxxdoc;'....'.,lxkdc'..........'.',;lll:,',,,'':ddl;;:;;cd    //
//    ..,:oddddc.  ..',.;c:'..,;::codddl'.'cdddxxdc,''';:ccc:'.'cxOx,     .....;lc,.';c:'.',;,,,;odc,',;:c    //
//    ....';cdOk;  ..','... .cddk00xlclxl'..;;,'','...':cllollllcdd;.       ..l0XX0d;.......,,,..,ll;''',,    //
//    .... ...',.  ........,',. .o0d,.'l00c............,;;::cldxxo,.....  ...,okOKNNKl,,'..',,'...,ll,..';    //
//    ,::..       ....  ..,llc:,'.,xOolk0Kx'....'''','''',;,,;:::;.. ........';cdO0Okxkxo:,..''..,;:c;'..:    //
//    .'..        .......':lcc;;:coOKl.,:;,'..',,;;;;,''',:cll::;;,...  .  ';;:odddc,;:::l:',;,'.';;,'',,,    //
//    .     . ..    ....';;c:..'lkKXNkoOd..',,;;;:::;;:ccc::cc:;'.''.     'xKK0K0kl:::;,,oo;:cc;,,,',;,,,,    //
//    c:'..';::,..   ......,...,:x0XNNNNd...',;::ccl:;clc:;',;,'. .''. ...c0NWWWXxcc;,;;;:odlcll;',,'',c;'    //
//    odolodxddc,,'''.;:;,,,...';okkkxl:,',;;:::lc;,;,,,,,,'....   ...,;'';oxld0kooc'...',:oxkKX0o;;,..,c:    //
//    ::ccodolllooooo:lxdlc;'..  .''...';',:,cc,;l;.  ....... ...  ..,c:;,;cc:dkxool:,..';:::cokKOc;;'.',;    //
//    ,;:clollc;;ccclc::c:;,',''..'....;o:';;;:,.,;;'.     .    .,l;'',;clc,;coOOl,,,...;::;;;':ddocll,.':    //
//    ,,,;:ccc:'...','..;,'''',:ldxoooll:,,,:;,'.......       .'lxdc'.'',;:cddodl...,::;:cc;;::cc,;;;l:'..    //
//    '...',,;;,...............';clllloc',;,,,'.. ......    .;xx:,:coxkkkxxkko,.  ..,;;;;;,'',''...',cc::,    //
//    ................  .......,cc:;;:cc;',,,'.... ........,okOdc;lxO0KXXXXKOo;....,::cloolc;::'...,;ll;c:    //
//                   ...  .....':cccllllc,..'''''.........cx0K0kc,;cloxOO000kl'...,;:::::cxKOx0Ol,''''clco    //
//        ..      ....,;,'.'''..;cccllllc:;'.','........',;cokkxo;'''';lodkkxl;.,;;,'...'l0Kko0WNOlcc;:dol    //
//    ..,lol;..,'';:;'.';,.',..';:cclllc::;,'.',.......''',;;:ccc:'..':colccc:;;;,,''....;dd;;kKKOo:;,,:ll    //
//    ...',,,...............'...,::ccccc::;,'...',',,:lc:::cccldkkdlclkOxc,;ccloc;:::;,'';:looxkocc;'',,:l    //
//    ',...';;;,....    .'......,:ccccccc:;,'.',;:cclcccccccloodxk00kdxkkc';::lc,,;;::;,..;ll:;c:;;'...',:    //
//    .,;,::::;,...    ..'.....',::c::ccc:,,'...,,,'',;;;;;:cclllcclddol:',loc,.....''.';coxxxOKd'..  .':o    //
//    ::,..'''';,...     .'....',;::::::::,'......''',;;::::::cccc:;;:clldkOxl,.     ...,ckXNNNXOc'.  .,:c    //
//    KKOxl,....'.    ..'..:oc'',;;::::::;,.......';codkkkOOkkxdlc:;,';d0KOdc:;........',,cdOKK00kl.  .;,,    //
//    xxxk00kl,.......':c;',:lc,,,;:::::::,... .':lxkO0KKKXXNNXK0ko:,.':odo:;lc. ...;;,'':lodkOkxdl,...':d    //
//    XKOkxdddl;,;;'''....'..,;,,,;:::;;,,,....;clodxkO00KKXXXXKK0Oko,.;dOxccol:,'..:xd,';cokKXXXkc;,'...:    //
//    O0XNNKxlc:;;,'.........,;,,,;:;;;,,;;'.,;;:clodxkkOOO00KK00OOkkoc:lxOxl:::;;'..,ol:lox0NNX0d;;::;,,;    //
//    ;:lxO0KKx:'...........'',,;;;::;;;;;'.',',;:cllooddddxkOOOOOkxxdoc;:c::;;;;:;'..co;;cox0XXkdoc;;,...    //
//       ..,:oxd,............'',,;;:::::;,..'.'',;;:cccllllooodxxxxdolll:,',ldl:::;;''co,.,clxKKO00dc:,...    //
//    ...     .,'.  .........,,,,,;;:ccc:,''...'',,;;;::::::cccllllllccllc::oxddxkdooodxoc:::cldxxl:,.....    //
//    ;cc:,..           ....',,;:::;::c:;,,,......''',,,,,;;;;:::clccc;,,;:lllllooollllloc;,'.;xKO:''.....    //
//     .;clc:'        .....',,,;:ccccccc;,;;'........''''',,,;;,,,;;;. .,cllccloolc::cc:'....'dKX0c,;;,,'.    //
//    .;dd;...     .......''',;;;;;;;;;;;;:;::;,,,'''',;:clllooc;;,'.  'clc::;:clc;';c:;,'...cxOOo;,;,,:::    //
//    dxkd;''.      ......','',;:::;,,,';:c;,;;:lodddxkO00KXXXXXK0ko;..,c:;,;;::cc:,:llc:;,,:okOko;..',',;    //
//    xd:..lOc      ......,;:::;,,,'''',;cl:,,;:okOOO0KXNNNNNNWWWNNX0o,.',:cllccc::cllllc;'':oooo;...',..'    //
//    c'...';'       ...',;cllc:;''..',;clll;;oxkOkkkO0KKKXNNNWWWWNNN0d::cccc::;::;;::cll:,;:cdoc,.. ..,;,    //
//    ::cl:','    ......,,',:ccc:'.';:::cclol;;lddolodxxkk0KXXNNNNNNX0kl;:::::,,'.'''';cc:;:ccc'.,;'';lc;:    //
//    ;cdkxoxd,.  .......'.',;::,..,cllloxkdoc;:cc::clooodxkO0KXXXXK0Oxc'.',;;,,'......;ccc;,,'...;lxkd:,:    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract nrhmn is ERC721Creator {
    constructor() ERC721Creator("Love And Death Celebration", "nrhmn") {}
}