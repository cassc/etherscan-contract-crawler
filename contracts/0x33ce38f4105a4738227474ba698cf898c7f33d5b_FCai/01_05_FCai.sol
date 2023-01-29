// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: FRaiK CREaiTIONS
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;    //
//    cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccccccccccc;;:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccc;,',;:cccc;..;ccllllccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccclc,.....',clc,..;looddoolcccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccldkx;........,cl;..cxkkkxddoollcccccccccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccoxO00Od'... .....;l;..lkOOOkkkxdollcccccccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccc::;:cldkOO0000xc,.   ....,:,.'dOOOOOOOkddoolllcccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccc:;,'.'',,;:cldxOOdc,.  ....'..,x000OOOkkkxdoollcccc:ccccccccccccccccccccccccccccccccc:    //
//    ccccccccccccc:;;'............,:ldxdc,........:k000OOOOOkkxdoollccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccc,................,:odo:'.....'lOO000OOOOOOkxdollccccccccccccccccccccccccccccccccccc:    //
//    cccccccccccccldOkoc;....... .........;lol:,';lxOOOOkddxxkOOOkkxxxxxxdlc:c:c::::::cccccccccccccccccc:    //
//    ccccccccc::cllc::,,'.........   ...,:ldkOOkO00000OOxdlcclldkOOOOOOOOOdccccccc:::::::::ccccccccccccc:    //
//    cccccccc::cldo:,'''............';cdkOOO00OOO00kdoddoc:,',::oxOOOOOOOOdlccccooc:::::::::::cccccccccc:    //
//    cccccc:::ccldddl::;,'.......';cloxkkkOOO00kkkdlc;,,,,,,''',:loxO0000Odc::::coc:::::::::::::cccccccc:    //
//    ccc::::::cclodkOOxol;'... ..:loxkOOOkkxkOkooo:;;,.........',::cdO000Odcccc:clc:::::::::::::::c::ccc:    //
//    ccc::::::cclook0000Oxl,...':ldxkOOkxddoclc;,,,;;,''...     ..',:dO00Odlccccccc:::::::::::::::::::cc:    //
//    cc::::::::cclok0O0000Oxl;',:lxkkxddddolcll;...;::::;''''..    ..;d00Oxllccccccc:::::::::::::::::::c:    //
//    c:::::::::cclok00000000Od::oxkkkkxxxxddooo:...;clllc;,,;,'....';:ldOOxlllccccccc::::::::::::::::::::    //
//    c:::::::::cclok000000000OOOOkkkkxodddl:,'''...',,;ccc::cccc;';dOkxdkKkolllcccccc::::::::::::::::::::    //
//    ::::::::::ccclk00000000000OOOkdoddddl'..... ..':c:;;:::;;;coodk00kkxdxxxxolllcccccc:::::::::::::::::    //
//    :::::::::cccclx00000000000OOxl:cddol;'.  ......'','',clc:;;:ldkO00KX0xk0XKOkdolccccc::::::::::::::::    //
//    ::::::::::ccclx00000000000Oxolcldollc,.   ...........,,;cclloolloxkOKXXKXNXXX0kdolccccc:::::::::::::    //
//    :::::::::::cclx0000000000Okolcccloddoc..     ............'',:looodddxkOOOKKXXNNXKOxoccc:::::::::::::    //
//    :::::::::::::lx0000000000kxlcclclooddl:'          ......  ....',;ldxxxxdooxOKNXXNNNKkolc::::::::::::    //
//    ::::::::cc:::cx000000000Okdc::lolloddoo:.........               ..,::coxkxdddxk0XXKXNXklccc::::::::;    //
//    :::::::::ccc:cx000000000Oxo;,:cc:ldddddo,'cooodddl:;;cc:ll::cc:,'',,'..,cloxxdoooxOKXKKOdlc::::::::;    //
//    :::::::::::cclx000000000Odc;,;:::ldllddoc;ck0OOOOOOOOOOOOOOOOOOOkOOkdl;'''.',;:lc:cldk0K0dcc:::::::;    //
//    :::::::::::::lk000000000Odl;,,;::cl:;lddxo::lloxkkOOOOOOOOOOOOOOOOkkkxxddolc:;,,',,'';oOKklc:::::::;    //
//    :::::::::::::ldkO00000000xo:'';;:,;;',coodddc,....'';coxOOOOOkkOOkkxkkkxdxxkxdoolc;,'.':kOo::::::::;    //
//    :::::::::::::looxO000000Okdc..';;,...',,:dddkd;..    ..,okOOOkxkkkOOOkxooodddooolloolc;':xd::::::::;    //
//    :::::::::::::coodxO00000OOxl,...''. ....,clloool,.      .cxOOkdlokOOOkollloollllccccccc;,:l::::::::;    //
//    :::::::::::::cloddk00000OOkxc......    ...,c:coo;...     .:xOkdoxOOkxoccc:cccccc::::::::;;::;;;:;;;;    //
//    :::::::::::::cloddk0OOO00OOkc..  .   .... .';:ll'...       'oxdxkOOkxlc::cccooc::::::::::;;;;;;;;;;;    //
//    :::::::::::::coodxO0O0OOOOko;.      .....  ..';c'..         .:oxOOOOOxlccol:ccccc::::::::;;;;;;;;;;;    //
//    :::::::::::;:cooddkOOOkOOOxc'.     .......  ..'...            .;dkxxOOkdllocccccc::::::::;;;;;;;;;;;    //
//    ;;;;;;;;::;;;:cccloooooolc;'.    ......... .  ...              .'cdxkkxolccccc:::::;::::;;;;;;;;;;;;    //
//    ;;;;;;;;:::;;;:::cllll:;'..          ..         ..              ..,cooollllllcccc:::::;;;;;;;;;;;;;;    //
//    ;;;;;;;;;:::;;;:::::;,..                                           ..,;::cccc::::::::;;;;;;;;;;;;;;;    //
//    ;;;;;;;::c:;;;;,,''...                                                ..',,;;;;;::::;;;;;;;;;;;;;;;;    //
//    ;;;;;;::::;;;,,'.....            ..                   ..          ..   ...',,,;;;;;;;;;;;;;;;;;;;;;;    //
//    ;;;;;;::::;;;;;,,'........  .....',. ......  .   ... ......     ..'. ...''.'',,,;;;;;;;;;;;;;;;;;;;;    //
//    ;;;;;;;:;;;;:;;;;,''....','..',,;;;,..,'..'...  ..,...''.'.... .;:'':l;.','',,;;;;;;;;;;;;;;;;;;;;;;    //
//    ;;;;;;;;;;;;;;;;;;;,...,,,,',,,;;;;;,',,',;'.....,,'..,,','.,,.,lolxOo;;,,,;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    ;;;;;;;;;;;;;;;;;;;;,',;,,,;;,,;;;;;;,;;,,;,','',,;;,',,',;,;;,,:ldkkl;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    //
//    ;;;;;;;;;;;;;;;;;;;;;;;;,,,;;;;;;;;;;;;;,,;;;;;,,;;;,',;,,;,;;,,;cdkxc;;;;;;;;;;;;;;;;;;;;;;;::cc::;    //
//    ;;;;;;;;;;;;;;;;;;;;;;:;,,;;;;;;;;;;;;;;,,;;;;;;,,;;,',,,;;,;;,,;:cll:;;;;;;;;;;;;;;;;;;;;;;;coxdl:;    //
//    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;,;;;;:;,,;;;,,;;,;;,;;,,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:looc:;    //
//    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;,;;;;,,;;,;;,;;;,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:::;    //
//    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;,,;;,;;,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:;    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract FCai is ERC721Creator {
    constructor() ERC721Creator("FRaiK CREaiTIONS", "FCai") {}
}