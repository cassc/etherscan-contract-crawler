// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Grim Triumph
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    .............................                         ..............................................    //
//    ...''..........................                          ...........................................    //
//    .''''................................           ...''..  ............'''''....'''''.................    //
//    .'''....................................      .:dk000Oxl'.........'''''''''''''''''''...............    //
//    '''''.......'''...........................   .ckk0KXKOOxl'.........''''''''''''''''''...............    //
//    ''''''''''''''''..........................  ..cdOKXNXXXOd;..........'''''''''''''''''...............    //
//    ''''''''''''''''.............................,oolk0XNXX0dc.......'''''''''''''''''''''..............    //
//    '''''''''''''''......................... ....:xdldxk0KXXOo:.....''''''''''''''''''''''''..........''    //
//    ,,,''''''''''''''........................... 'xOOkdddxO0Oko,...''',,,,,,,,,,,,,,,,,,''''''.';lc;,,,'    //
//    ,,,,,,''',''''''''''.........................,x0Oo:okxdddxkx:''''',,,,,,,,,,,,,,,,,,,,'''';;cdoloo;'    //
//    ,,,,,,,,,,,,,;;,'''..........................,dO0xllcldxxddd:''''''',,,,,,,,,,,,,,,,,,,''';lclolxOxc    //
//    ;;,,,,;;,,clc:;;;'............................cxdolcldoollod:,,,''',,,,,,,,,,,,,,,,,,,,,,,,;cokOOKX0    //
//    :;;;'''..:kO0xoOk:...........................;kkl;;,,''''',ldc,,,'',,;;;;;;;;;;;;;;;;,;;;;,,,l0KO00k    //
//    :cc,....'okxkOO0Kx,..''.....,:;,;,'.........lOOdc,'',,'''',;llc;,,,,;;;::;;;:c::::c:;;:::;;;,;lxxkOx    //
//    ;::;''..ll,'':do:;,':cc:;,,;::::::;;;;'..,:d00dc:;,,,,,,,,,,,;:ll::::::cc:::cl::::l:;;;;:c::;,;:cdO0    //
//    .;:;;:..odclxxdccl,':::::::::::::;'.;;'';lk0Odc::::::;;;;;;::cloxdlcccccccc::::::::::::cccc:::;;;:ok    //
//    ';;;;;::;,.;dxdxxl,,;;;;;;::::::::;,;;;,:xKOxl;;:ccccccccllllllodkkdllc::::cccccccccccccccc::;;;;:co    //
//    :::;;':olc;..,;;:'.;;;;;;;;;:cc:::;::;,;d0Okd;..';ccclllllllccclddkOkoc::cc::cccccclcc::cccc:::;:::c    //
//    ccc::;:c:lol;:cc:',:;;;;;;;;ccc::clc;;oOKOxxc....,:cllccc::c::::lddk0Oo:::::clccc::cc::cccccc:::::::    //
//    ;:ccclol;',clcloc;;;;;;;;,;;;;:codo::d0K0kxl'.,',;,:llccclcc::;;:lddxOOo:ccccllcc:::cccccccc::;;;;;:    //
//    ,cl:;:c:;;,;codo:;:::::;;;;,,',lol::l0K0Oxd:.';,::;;clcllccccc:::cldddkkolllcccccloooddlcccc:;;;;::c    //
//    c::;;;;;;;;;::::::cccc:::,..';clc:;:x0Okxdl,.',:c:;:lccc::::cclc;:cododxxolllccccoooodxoc:::::::cccc    //
//    '''''.''''''''':llllllllc,..cdlc;;:oxkdddl,...,,''';ccc::::::::,.':llloddlccllcoolc:cooc:::::ccccccc    //
//    ............''.':ccc:;:cc'.'c::::clllllool:;,''',:clooooll:,''''',lxdloxkocllodOK0kxoc:::::cccc::::c    //
//    ...........'cdc;;ccc;'';::c:;;:cllccloodxxoc;,'':oxxxxddo;.......,oxxddxkxlcldkkxdollcc:::cc:,,'''''    //
//         ..'..'okd:ll::;,'',:x0d:;;odl:;cddxkOkl:;cdOOkkxxOOxl'......'oxxdxxkdlcccc::cllllcc:cc;..;:,''.    //
//          ':;..;oooxd:'..''',;:llclxkl,,lddxkkkl:oxxkocclllcldo;''   'lxdddxdo::clc:cloolcccccc,.:kxlll,    //
//          .';....;lol'.,,,'....,lxkkd,.,oddxkkx:'okxxoco0KkkOxol:,....coddddoc;cooccclllcc:::c;..:lll:,'    //
//      .,..':c,. ..',;;oO0x:.....;xOk:. ,oodxkxx;.;odl..'lolldl;:ccc:..:ooddolcclol:::;;;;;;;;;,..;;,:llc    //
//    .'clc;,;cc,.. ..,;lxkd:.....,dkd;..;lodxxxd;..;lkdccoddoodlcolc:,,:lodoloolc::;;,,,,,,,,,,,'.;oocdkd    //
//    ;odol::::c:;..;odoldo:,;,'..:oddc:cccodxddoll:..:dolc:::cdocc:cldxlcooclkxc:;,,,,,,,,,,,',,,'';:;;;:    //
//    occllcll;',c:;llcodxxlc,.';cdkOOO0kcclodoolxOo,'lo::;,',:oddoookXXkccc:d0kxdc;,,;;,,,,'',,,'''';::cl    //
//    Odc::cc:,,lxoodl::::coxo:cxkxkKXXKOocclll:oOl.';lddolc;coodxxxxOKXKxl:,l0kxko::::;;,,,,,,,,',,',cll:    //
//    0Oxc;;,;okOo',c:;;;;,;lkdlx0kk0K0K0Odlcc::xKx;...,::lollolccc:;,lOK0kdoxkxxdolc:;;;;;cdkOOkxl;'....'    //
//    kkOo:;;;dKXd:;:::::clc;'..:oloO00KKK0OxdxOXKx:.....,clddoccl:,''l0K0OO0Oocllcclc:cclxO000000kdl'..,,    //
//    .';lc:lddkXKkocccccldd;. ..,;cO000000OkkO0KXXKxl:,,'',:c;,c:;;lkXXXK00KOc;::;,:ccodolcc::;;,,::',;:;    //
//    .....':c;::;:llccodxxdl....':lk00OkkkkkkO0KKXXNNXK0kc,;;',c::xKWNNXK0KKk:,;;,';:coc:dkxddol;,;;:oc,.    //
//    ..lko,,;,;.':cxxdkOOkOx'....;ldOOkkkkkkkk0KKXNNNNNNNXOdc;:coKNNWWNXK0K0c'',,,;coxxlckXXXXXk;..;cllod    //
//    .;ool;':lc;ck0XX0kxk0XO,....'ldkOkkkOOOkxxKXXXXNNNNNNNXx::cxXNNWNNNX0Kx. ...,;;:clollOXKKOc.,:;co0NW    //
//    co:;:llcldloxOKNX0xxkxl,.....;dOOOOOOkkkoo0XXXXXXNNNNNNk:;:dKNNNNNNNX0l.    ....',;;,l0K0xl;:;';xXNN    //
//    odddxxxolooxk0KXNXKOxl;......'oO0000OkkkkxKNXXXXXXXXXXXOc;;lOXXNNNNNNk,          ..,,,oOxdoxo;,:dO0K    //
//    llc,;okxlldxOKKXXNNNXOo'.....,x0K000OkkOkdOXNNNXXXXXXXXKd;,l0XXXXNNNNd.            .,.,oxxxK0c;ck000    //
//    codoccldxO00000KXXXXKKOo;''..c0XXK0kdoooo:l0XXXXXXXXXXXK0Oxk0KKXXXXXNO'            ... .',oKx;,l0XXX    //
//    .,:lodxk0XXK0KXXXXKKKKKK0kkxkKXXXXXx;''',,:OXKKKKKKKXXXK00000KKKXXXXNXl                   c0l,,cOXXX    //
//    cc:;lOKXXKK000KKKKKK000K00OO0XXXXXXO:,,:coxO00OO0000KKKKK0000KKKKKKXXNk.    ,:.     ..   .dKo,;cOXXX    //
//    k00kOKKKKKKKKXXXXXXXXXXXXKKKKKXKXXXKkdxkkO0000000000KKKKKKKKKKKKKKKKKKKd;,,;dk:'..........l0kdx0XXXX    //
//    O000KXXXXXXXXXXXXXXKKKKKKKKXXXXXXXXXXKOkdxO00000KKKKKKKKKKKKKKKKKKKKKKK0xoddxkxlc:::::::::oOOOkO0000    //
//    KKKXNNNNNXXXXXXXXK000000000KXXXXXXXXXXKOkO0KKKKKKKKKKKKKKKXXXKKKKKKK000Oo;:cdOkdllccccclclk00OOOOOOO    //
//    XXNNNNNNXXXXXKKKKKKKKKKKKKKKKKXXXXXXXXXK00KKKKKKKKKKKKKKKKXXXXXXXXKKK00Oc...;k0kl;;;:cldk0KKK000000O    //
//    XNNNNNNNXXXXXXKKKKXXXXXXXXKKK0KKXXXXXXXXKKKKKKKKKKKKKKKKKKXXXXXXXXXKKK00o...'x0k:..'':okXNNXXXXKKK00    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract nrhmn is ERC721Creator {
    constructor() ERC721Creator("The Grim Triumph", "nrhmn") {}
}