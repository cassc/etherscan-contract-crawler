// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Rare Scrawls
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    ;;;;;;;;:::::::::::::ccccccccclllllllooooooooooollllllllllcccccccccc:::::::;;;;;;;;;;,,,,,,,,,,,,,,,    //
//    ;;::::::::::::::::cccccccclllllllloooooooooooooooooollllllllccccccccccc:::::::;;;;;;;;;;;;;;;;;;,,,,    //
//    :::::::::::cccccccclllllllllllooooooooooooooooooooooooooolllllllcccccccc::::::::::::;;;;;;;;;;;;;;,,    //
//    ::::::::ccccccclllllllllooooooooodddddddddddddddddddddoooooollllllllcccccc::::::::::::::::;;;;;;;;;;    //
//    ::::::ccccccccclllllllooooooodddddddddddddddddddddddddddoooooooolllllllllccccccc::::::::::::;;;;;;;;    //
//    ::::::cccccccllllllloooooooooooddddddddddddddddddddddooooooooollllllllllccccccc:::::::::::::::::;;;;    //
//    :::::cccccccllllllloooooocccclllllllllooooolllllllllllccccc::::::::::;;;;;;;;;,,,,;ccc::::::::::;;;;    //
//    :::::cccccllllllooooooddocccccllllllllllooooooolllllllccccc:::::::::::::;;;;;;;,,,:cccccccccc:::::;;    //
//    ::ccccccllllloooooddddddolcllllllllllooooooooooooolllllcccccccccccccc::::::::;;;;;cllllccccccc::::::    //
//    ccccccclllloooooddddddxxdlllllllloooooooooooooolcc::;;,,'''''',,;;:ccccc::::::::::collllllcccccc::::    //
//    cllllllllooooodddddxxxxxdlllooooooooooooooollc:;,,'''..............';:cccccc::::::cooollllccccccc:::    //
//    llllllooooooddddxxxxxxxxdoooooooooooddodolc:;,,''''..................';:ccccccc:::looooolllllccccccc    //
//    llllloooooddddxxxxxxxxxxxoooooooddddddolc;,,''..''',,,,,,'.............';cccccccccldddooooolllllcccc    //
//    lllooooddddddxxxxxxxxxkkxdoddddddddddl:;,''',;:coxkkkxxxdool:;,..........,:llcccccoddddoooolllllllcc    //
//    ooooddddddxxxxxxxkkkkkkkkddddddddxdl:;,'',clddxdollldkkdllllllc,..........,clllllloxxddddooooolllllc    //
//    ooooddddxxxxxxkkkkkkkkOOkxddddxxxoc;,'';clccloxkOxdc:lddollooc::'..........,lolllldxxxxdddddooooooll    //
//    lloooodddddxxxxxxxkkkkkkxdddddddl:,'.,lkko;;lc,,coodollloddlcloc'...........;loolldxxxxxdddddoooooll    //
//    cclllloooddddddxxxxxxxxkxooooool;'..;x00Okdooc'';;';ccoxdlcldddc............'collldxxxxxddddddooooll    //
//    :ccclllooooodddddxxxxxxxdoloooo:'.'lOK00Okkkxdc::;,,cxxlcldolcl:.............;lllloxxxxddddddoooolll    //
//    :::cclllllooodddxxxxxxxxdllllc:,..lOKK0Okxdddolccodxxoc::dkkxoc:..............:lcloxxxddddooooollllc    //
//    ;:::cclloooodddddddddddxdccccc;..:k000Okxdolllcoxxdl::cc;;lkkxoc'.............,cccodxdddddooooollllc    //
//    ;;;:ccclllooooodddddddddoccccc;..;dkkkkxxdolcoxxo;,',;codl:lxdlc,.............';ccodddddddddooooollc    //
//    ',,;;::cclllllooooddodddoc:::;'..'lodddoolcoxxl:clc:::,,:loclolc,..............;ccoddddddddddooolllc    //
//    ,,;;;::::cclllooddddddool;;;;;'..'odllodl:oxdc:loxxdll:,,,;:lol:'..............,:codxdddddddooollccc    //
//    ',,,,,,,;;;:ccloooddddddl:;;;;'...lxdolll:ccccldxkkkxdol:,;clc:'...............':coddddddddoooollcc:    //
//    .''',,;;;;;:::ccccllodddoc::::;...:dxdoccclcloxkOOkkxxxdooll:,................'';cldddddddddoooollcc    //
//    .''',;;;;;:cccccccllllllc;,;;;;..':coddolc:codkOOkkkxxdoolc;'..................';:ldddddddddooollllc    //
//    ..',;,,,,;;:::cccccccccc:,'''',..',';odool;.,:oxxkkxddolc:,....................',:ldddddoooooolllllc    //
//    ,,,;,,,,,;;;;:::::cccccc:,,,''';;;cllcc:;:;...,coodollc:,'...  ................',:coooooolllllcccc::    //
//    .''',,;;;;;;;;;:::::cccc:,,,,:c;'cddddoc;;;,...':cc:;,...'.   .................',;clllllllllcc:::;;;    //
//    ..'',,,,,,,,,,;;;;;:::::;'',cc,.'cxxxxxdddoc:;;,;,'''.       .................',;;collllcclcc::;;;,,    //
//    ...'',,,,,,;;;;;;;;;;;;:,.;l:....;dxxxxxxdooccodl;.',.       .................'',,:llllllllcc:::;;;,    //
//    ...''''',,,,;;;;;;;;;;;:,'lc......;odoooolll::::;;;,'.      ..................',,,:ccccllllcccc:::;;    //
//    .''''''',,;;;;:;;;;;;;;;,;d:....'.'cooolcc:;,;;:::::,.      ..................,;;;:ccccclllccc::::::    //
//    ..'',,;;;:::;;;,,;;;;;;;,lx;,;;;;;;dkdol::::cllccccc;.        ..............,:cccccllllllllccc::::;;    //
//    ..''',,;;;;;,,,;;;;:;;;,:kd,,;;;;;,d0Okdoc:ldxdoooll:.        .............':llllllllllllllcc:::;;;;    //
//    .....''''''',,,;;;;;,,,'cdc,,,,,''.ckxxkxlcokkxxdllcc,.      .............';::cccccclcccccccc::::;;;    //
//    .....''''',,,;;;;,,,,,:cllllcclllccloclxoccdkkkkdllll:'.   ..   .........,ccc:::::::::::::::::;;;;,,    //
//    ....'''''',,,,,,,,;coxxlclllc::::;;;:clc::ldkkkkxdddolc,.       .......':cc:;;;;;;;,,'''',,,''''''..    //
//    ....''''',,,,;:codk0Oko::c:;;,,;;;;;;;:c:::lxkOOkdddollc;.      ....';cllcc::;;;,,,,''''''''........    //
//    .......''':odxkOOkkkkdc:cloollcc:,,cc:;,',,;cdkkxddddoll:;,.   ..';:cccc:::;;;;;;;;,,,,,,'''........    //
//    ......'''lO00Oxdxxkxdl:;,;:clllc::cl:',::;',:ldddxdddoll:;c:'.';looollcc:;;;;;;;;;;;;;,,,,,''''''...    //
//    ........'oOkxddxxdol:,,;ldxdoc:,..,'.;:cl:,,cdxxxxddolcc;;:;,:;;do:ccccc:::;;;;,,,,,,,,,,,,,,,,,''..    //
//    ........,dkdlccc::;,'',:cc::;,'......:llxd:;codxdddol:,':l,.;ko':d:'',;;;;,,,''''''''''..''''''.....    //
//    ........:xxdl:,'''',,,,;;;;:coool:,,,;oddxxolc:loolc:,..o0c..cxc..,'';:,'''....''''''..'''..........    //
//    ........cxxxol;'.'''''',:ldxk0KKK0xl;.;lodddll:;c::;ox,.'oOo...,:dO0K0ko;..''''''...................    //
//    .......'okkxol:'.'''',,:cc;,'''',;,..ox:,cllllc;;,..oX0c..,:..o0WMN0dc,.................''..........    //
//    .......'dOkxolc'..',,;;::cc::,'.....l0o.'oo;;:;';dkc.;okl. .;0WWKd:....';:clol,...........'.........    //
//       ....,xOkxolc'':oxkO0KXNWWNXK0koc,,'.'dXd..dd,.cxOx,..'..lXWNx,...'ckKNNNXNN0c'''.................    //
//        ...;kOkdooclOXNWWWWWWWWWWWWWMWWXOdcdOo.'xKl,:'.'do. .,xNWXl....l0NWWWXOxolc:,'''''.'''''''......    //
//          .:kkxollcxNX0kdolcccclodxk0KNWWWNKk:,xKc..c:...'':dXWMXl...,kNNX0xl;'.....';;'........''......    //
//          .ckdolloc:c;'..............';cldkOKK00kcodkkxxkOKWMWWK:...;ONKx:'.....';ldk0KOl,'''''.........    //
//          .lxdoolc;........''''''...........,:ldxOKXWWWWWWWWWXd,...:0XOc.....,lxOXWWXKOkd:''''''''......    //
//          .oxdolcc,.':lodkOO00000Okxdoc:,.........,:cooddddoc'....:OKk;...'ckKWWXOdc;,'..'''''..'.......    //
//        . ,ddoolc:;oKXNNWWWWNNNNNNNWWWWNX0kdl:,.................'o0Kx,..'l0NWXOl;....',:lodd;...........    //
//       ...;oooolc:;kNNXKOxdocc::::cclodkOKNWWWX0kdl:,.....'',,;;ldxd'..'kNWNk:....,ldOKXNNNXk;..........    //
//         .;llocc:;;ldl:,................',cokOOOOOOOOkxxxkOOkkkkdoc'. 'xNN0:...'ckKNWN0kdl:;;'..........    //
//         .:lll::;;'.......'',,;::ccloodxkkOOOOOOOOOOOOkkkOOkkkkkxxoc'.oKXx'...l0NWNOo:'.......'.........    //
//         .:llc;,''...'',;:llodxxkkOOOOOkkkkkxdddxddddddddddddxxkkkxdc;cxl...;kNWKd;.....';loxkOx, ....      //
//         .clc;,'...,,,,,,;;;:::ccloodddddddoooollc:c:;;;;;',:loxkkkxoc:,. .c0NXd'....'cx0XNWNKOx;.          //
//         'cc;,,,,;::;;;;,;;;;;;;;;;;;:;;,,,,;clodddxxolc:;,,,;:ldxxxxlc;'.c0Kk;....:xKWWWXOo:'....          //
//         .,,;;;;;,'...........................';:lodxkkO0000k:,:codxxoc::;;ol....;kNWWN0o;.. ..':oo,.       //
//         . 'ol;'........';clodxkkOOOOOkkxdol:;'.........',;;:,.,:codddolcc;'.  .c0NWW0l.....;okKNNKo.       //
//    .......':'    ..;ldOKXNNNXK0OOkkkkkOO0KXXXK0kol:,......    .';cllllllc:;,..oKKXXd'....ckXWN0d:'..       //
//    ...... ... .,lx0XNNKOxoc:;''..........',;:loxOKXXK0Oxolc:;;;;,,;:::::::;;,'ckKk;. ..l0NWXk:.. ..;:.     //
//           ..';oKNNKko:,.........'',,;;;;,,''......,:lodkO0KK0OOOl..'',,;;,''''.,:.  .:ONNNO:. ..;loc:.     //
//            ;dxkXXx;. .......':ldkO0KKXXXXK0Okdl;'........';::::c:.......''.......  .cKNNNO' . .xKk:...     //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract RS is ERC721Creator {
    constructor() ERC721Creator("Rare Scrawls", "RS") {}
}