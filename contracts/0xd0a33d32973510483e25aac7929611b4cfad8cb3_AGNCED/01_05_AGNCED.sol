// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ALLGASNOCLASS EDITIONS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    ...;lolcoxxdo:,''''..',;;clllc:;,''',;::::cccc::::::::::::::ccccc:c:::;;;;,'................  .....'''',,'........',;;,.    //
//    ,....,collodxdl:;,''''''''',;:cllcc:;,''...'',,,,,,,;;,,,,,,,,,''''.................    ......''''',,''........',;;;;'..    //
//    o:'....,;:::clddoll:;,,,'''''''',,;:::::;,''.............................................'',,,,,;;;;'........'';;;;,'..'    //
//    odl'......',,,;ldxxddol:;,,,,,,'''.''',,,,,,,,'..................'..........''..'''''',,,,;;;::;;,'.........';;,,''...';    //
//    'coc;'..,,...',,;codxxxdolc:;;,;;;;,,,,''',,;,'....,,,,,,,,''....';,,;,,,,,;;,,,,,,,,,;;;;:cc;,'..........';;;;,'....',;    //
//    .';ldl;..';;...',,;:coxkxxxxdlc::;;;;;;;;;;;;;;,'.';;;;;;;,,,,,..;:;,;;;;;;;;;;;;;;;:clol:;;,'.....'''.'',;;,,,'....',;'    //
//    ..',cddl;..,::'...',;;coodxxxxddolcc::;;;;;::;'....,;;;;;;;'.....,cc:::::::;;::cllccccc:;''...'''''''';:c:;;;,''''',,,..    //
//    ,'''';oxdc,..:lc,....,;::cloddxxxxxxddoolcc::,... .,;;;;;;,.... .'c::::cccccllllc:,,,''....'',,'...',:cc:::,''''',;;'..'    //
//    :;,''',cdxd:'.,cll;....',;:;:clloddddxxxxxdoo;...................'cccclllccc::;,,,',;::;;;;,,''''';;:c:::;''''',:::'..'.    //
//    dc;,''',:lxko;..,col:,....,,;;;;;:cooooddddoo:...........,;:::;;,;:c::ccllccc;,,,;cdOOxl;;,,,,,,;:c:;::;,''''';cc;'.''..    //
//    Oxl;,''',,:okkl;.';cooc;'....',;;;;,,;:cllllc,.............',;::;::;,:ol:;:oxd:,lxxddxxdc,,;;;;;;:::c:,''''',;cc;..''.',    //
//    dOko:;,''',:lxkkl,',:ccllc,'....',;;;;;,,,,;,...............',;::::;:dxc;''':k0kOxoc;,oOxc;clc:;:cc:,,'''',;:c:,..''.';:    //
//    :dOOxc;,'',,;:ldkxl;,;:::clc;'......',;;;;;;'..............'',,;;,;;lxkl,;cldO0OOkdo;.;xOl:cc:::c:,,,,,,;;clc;''''.'';lo    //
//    ,:dO0kl:;,,,,;;:okOxo:;:c;,:llc:;,''.....',;..................'',;cxkxollxOOOOkxo:,'..'dOd:;::c;,,,,;;;:cooc;,,;,''';lol    //
//    '';lk0ko:;,,,,,,;clxkkdc::;,,;codol:;;,,,,,'....;c,....... ...'.,cxOOkdoxxkdooc,'......:OKd:;;,,,,,;;::ldl:,,,,,'',;clcc    //
//    ;',;lx0Odc:,,,,,;;;:oxOkxocc:;',:odddolc:;;,...'ll;......  .....,lx0Ox:ckOk:'clll' ....:ONO:,,;;;;;::ldoc;'','''',;cllll    //
//    :;;,:lxO0kl:;;;,,;;;:codkkxdlclc,,;:loddooo:....,'.......   ...'cxO0OdokOO00kOxlc,.'..,ckNXd:;;;;::codo:,,,'''',;:cclcc:    //
//    :;;,,;lxO0kl::;;;;;;:::cloxkxlclol:,',;:cooc,''...'''''........,lkOOOO0kodO000o..,;'..,dKXKx:,,;::lddc,,,,,''',,:llccc:;    //
//    :;;,'';:ok0kol::;;;,;::cccloxkdollool:,',;c;..........     ....':xOO00kooxOxodl,',....'l0X0o;',:looc;,;;,''',,;:colc:::;    //
//    c:;,'',,;lxO0koc:;;,;;::ccccloxkxxdooooc:;;,...........       ..:x00OkkO0Okddkxo;.....;dKX0o;,:loc::cc;,,,',;::clollccc:    //
//    cc:;;,,,,;cdkOOxoc;;;;;;clcc::cloodxoclllool,...........       .;d000kkkkdl:okOkd:,'':x0KXklcccc::cll:,,,;;:cl:collcccc:    //
//    clc:;,;;,,,:cdO0Odl:;;;;::ccc:::cclllll:;;cc'............      ..:ok000kxdlccol::ccccd0KXKklc:;;:lc:,,,,;:loooc:c::;;::;    //
//    c::cc:;;;,,,;cokOOxocc;;;;:cllccc::ccc:;;;::'.............       .,d0K0xoodl;''',;:cdOKXXKd:;:::::;,,,;;:clolol;;::;;:;;    //
//    c::ccc:::::;,;:lxOOkxol::;::ccccc::cloodxxkko'........           .'lxOOxooxd:,',;:cokKXXXOc;:lc;;;,,,;:clllcc:;,,;;;;;,;    //
//    ccccllc:::::;;;;coxOOkdlc:::::ccldxk0KKKK000Oxc'.....           ..':ccoolodl;;;;;;;ckKXX0kl;;:;;;;;;;:collc:::,,,,,,;;;:    //
//    llcclolcc::::::;;:cldkkxdolcloox0KKK00KKK000000ko;..           .'ldol:,',;::,'....':kKKKkl;,,;;;,;;:cccccc:;;:;;;;;;;;;:    //
//    cclllllllc:;:::::;;;:oxkkkddxOkOKKKKKKKKKKKKKKK00Oxo:'..  .....;kOo;'..;l:''......'cOKxoOkl;;;;;;:cclolc:;;,;;;;;;;;;:::    //
//    :coddoccc:::::::::;;,;coxkOOOOkOKKKKK0kkO0OkkxkO0Oxxxxdocc:;;;o0Kd,..'cxOdcol:,...:oO0l,lxkxl;;;:looddo:,;;;;;;::;;;::::    //
//    ;;cldxoc:cccc:::::::;:oOOOOOkkk0KKKKKkooddc;llcool:::coxdooodkKXOc..,;:ldo:cdkkdcckKK0c.':okxoc::lddddlc:::::cc::::;::;;    //
//    ;,;:ldxoccccc:::::;:cok0kxOkxxOKXKOxxxdddoc;cooodxxdc:cllclkKXK0o''cc;;cllc;;cldddOKOk:...,;oxxc:llllcccc::::c:;::;:::;;    //
//    ::;;:ldxolcc::c::;:loldOddxddOKKKKOxxxdlodoclolodxxxo::loclx0Okc.':oc::lc,,,,,:oolxK0Od'....,cdxdc;:::cc:;;::::;;;;:::;;    //
//    :::;;:ldkxoccc::::odcokdllllxO0KKKKOkxdodxdodooxodxkkdddddxkkxo;;llll::llc:::;:cl:cxl,;;....';coxo:,,;;::;;;;:;;;:::::;;    //
//    :;;;,;:ldxxolc::cdoc:dd:clccccoxkkdxxxxxkxdddoddodxxdoollooxkkkdlllclc:c:;;;::cc:,,,. ......',,;;,....,;:;;;;;;;;:c::::;    //
//    c;;;;;;:coxkxlccooc,;c::;;;'..',:coxkxxkkOkddooolddc;;,,,;cooxOkoolll:::cll:,',;,...        ..........';;;,,;;::::::;:::    //
//    c::;;;;;;:lddlc;,.................:dkxxkkOOxdoolccl:''''':lolxOxooooccllldxdc,,'...             ......;:;,,;::::cccc::::    //
//    lll:;;;;;;::::;...   . ............'cddxkxxxxdolc:;,....':ooodxxxdolllccoxolll:'..               .....,::::clc::cc:::::;    //
//    ccccc:::;;;;:;...    .......  ......'codkxooodoc;,'.....':odxxddoodxdc:loolccc;..     .... ..       ...';:clllc:;::;:::;    //
//    c:cclc:::;;:c;'..               .....';oxkxl::::;'.....,,:oddooddddlc:clloc:c:'.      ........      ....,cllcc:;;::;;;;;    //
//    ccccllc:::clc;'..      ......  .......':looc,'..... ..',,:ddlccol:;,:lllol:;,'.       ...;'..     ......,:ccl:;,,;;;;;;:    //
//    ::clodlccll:,...      .;:'.;:'',;'.....;;.',...     .;lolcc;,;::''',co::cc,'...      ...'::,.     ......,;;:cc;:::;;:::c    //
//    c::codoollc;'..  .. .':do'.';''cc'............   ..';coddl;,'';;....';'..'......      .......      ......,,,;::;;::;::::    //
//    :::clllooc;,..........':c;'''.;o:.....        ..';cll:;:;:ccc:;;..................     ....        ........',;;:::;:::::    //
//    c:ccclodl:;'....',;ccc;cdo:,:ldd,..... .. ...;lddlocc:;:cloll:;::;c:;'..      ....      ...    ........ ....':cccc::::;;    //
//    c::cclol:;,'...';:odddxkOOxoodxd:....  ....',lkOxloccl::lodolcc:;:clllc;..   ......... .       .......  ....':cccc:::::;    //
//    ccc:ccc;''.....,;lxdddxkkdclclxxc'..     ...':dkkxoc;:::ldxxddoc',ccc::;'.   ...............................';c:::;;;::;    //
//    cccccc:,'......'coooodxxdcldxkko;...    ...''';ldkxo:,,,:oddddol::c:;,'..    ...............................':c:;::;;;;;    //
//    ccccll;'.......';ccclodocclodOOxc.........,'...';clc;,'';ldddollc:;,'.... ...  ........................'. ..;:;,,;;;;;;;    //
//    ::cloo:'........',':lol:::;;:lxxc'.......',,,..'''''',;;:lodoolc:;,'....  ....  ......... ........ ...... ..;:;;;;;;;;;:    //
//    c::codo;'.........';:;,'''''',:c,...''....,::,';:'..,:cccclodoocc:;,...   .....  .......  ........ ...    .';;;;;;;;;:::    //
//    :::cloo:'.......'','.''.''....'......','.,codc......';cooloolc:;;;,'...  ......   ......  .....    ..    ..,;;;;;;;;::::    //
//    ccccllll:'.....';;:;::::::,...............:ool:..  ..;ldkdol:clc:,...    ......   .....    . ..        ..,,;::::::;::;;;    //
//    c::clolclc;....',:codddoooc'..................'..   ..,lolc:;;,,''.............    .....      .       .,::::cllccc:::;;;    //
//    c:::cllccll;'...',:lolldoc:,....'..........;.       ..,;;;,''.......... ..,,'..     .....           ..,;::ccclc:c:;;;;,;    //
//    lcccclcccclc;''''',,'';cc;;:'...'..    ...cl,.       ..;;;'.......   ..,lol:,..       .           ...;c::::cccc::;;;;;,,    //
//    ccc:cc:clllc:;,;,',;'.'',,;,'...........,:c,.         .;c;..... .     .;ddddc,...,,'..      ... ..,:::::::;;:cc;;;;;;;;;    //
//    :::cccccccclclolc;;;,'........',,,:;'.';:;..          .':,..... ..     .:lodddoooxxdc,...   ....';::cc:;;;;;:::;,,;;;;::    //
//    c::looolccllloooolc:;,........;lccc:,......            ..... ........   'loc,'',cl:,,,,'.......'::;;:c:::;,,,;:;,,,,,;::    //
//    cclllddolool:ccclolcc;..........'',,..                 .. ....,:::'...  .,c:;'.................;c::cc:;::;,;;;:;;:;,;;::    //
//    cllllllllodollllllollc;,,,,,,'......            .  .      ...;odoc,....  ...................',;clc:cc::::::::;;;;c:;::;;    //
//    cllollclloddddolloodoolllllll:.         ....  ......       ..:ddl:'.....     .   .........,;;ccccc:::::::c:;;;,;;c::llc;    //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract AGNCED is ERC1155Creator {
    constructor() ERC1155Creator("ALLGASNOCLASS EDITIONS", "AGNCED") {}
}