// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: A KNIGHT RENDS
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                        //
//                                                                                                                                                                        //
//                              ..,;;,,'''''''''............',,;;;;;;,,,,,,,,,,,,',,,,,,'''''''',,,,;;;;;,'........',:codxxddoolllllllloxOkxxddxxkkkkkkkkkkkkkkkkxxxxx    //
//    .                       ..',;,,,,,,,,,,,'''.........',,;;;;;;;;,;;;;;;;;;;;;;;;;;,,,,,,,,,,,,,,,,;;;;,'........',;:cloddxdoolloodk00Okxxxxxkkkkkkkkkkkkkkkkkxxxx    //
//    .....                 ..';;;;;:::::::::;,,''......',;;;;;;;;;;;::::ccccllcclccccccc:::::;;;;,,,,,,,,;;;,'..........'',;:ldxxxkO0KK00Okxxxxxxkkkkkkkkkkkkkkkkkxxx    //
//    .............        ..;;;::clllllllooolc:;,'''',,;;;,,,;;::clloddxxxxxxxkkkxddddddddddddoolc::;;;,,,,;;;,'..........'',;:coxOKK0OOOOOkkxxxxkkkkkkkkkkkkkkkkkkkk    //
//    .................. ..,;:ccloollooooddxxxdol:;;;;;;;,,,,;:ldxkkxxxddoloodxkkdlcccclllllooodddxxddool:;,,;;;,,'.......',;;;;::cldk0K000000kkxxxkkkkkkkkkkkkkkkkkkk    //
//    ....................,:cloooollllooddxxkkxdoc::;;;,,,,;codxxdlcc::ccclodkkdlc:coxkO0Odlcccccclloddxxdc;,,,,;;,''''',,;:lllcccccclxOKK000K0Okxxkkkkkkkkkkkkkkkkkkk    //
//    ...................;cloooollllloodxxkOOkxxoc:;;;,,,;lodol:;;;;:ccllodxkdlccoxO0K0000K0xocccccccccloddl:,,,,;;;,;;;;:coddooolllcclok0K000KK0OOkkkkOOkkkkkkkkkkkkk    //
//    ..................;coddoollllloodxkkOOxo:;,,,;;;;:ldoc;,,,;;::cllodxxdoldk0KK00OOOOOO0KKOdlccccccccclol:,,,,;;;;;;:oxkkxdollccclllodOKK000KK0OOOOOOOOOkkkkkkkkkk    //
//    .................;coddoolllloodxkkOkd:,......',;:ll:,,,,;;::cloodxddodk0KK0OO00000000000KK0xlccccccccclc:;,,;;;;:lx0K0OkdolccccclloodOKXKKKKKK00OOOOOOOOOOkkkkkk    //
//    ................,coddollllloodxkOkd:'.........'',,,,,,;;:ccloddddold0KK0000000000000000000KXKkolccccccccc::;;;::cldxkOOOkdoollcccclodxOKXXKKKKKKK00OOOOOOOOOOOOk    //
//    ...............':lddolccllodxkOOx:'.......''''',,,,;;::clooooollc:lx0000000000OOOO000000000KXNXOocccccccccc:::cccllcloxkOkxdoollccclodxOXXKOkxxxO0KK0000OOOOOOOO    //
//    ''''''''.......,codolcccclodkOOd;....'''''',,,,;;;::cllooollcc:cc:lx0000000OkkkkkkOOOOO00000KXNXdccccccccccccccllccllllodkOkxdoolllllodx0X0dddodddxkO00K0000000O    //
//    ;;,,,,,'''''''':lool::::cldxOOx:''''',,,,,;;;;::cclllllccc:ccccccccldkO000OkkkkkxkOOkO0KKK0000K0dccccccccccccccllllllllllldkOkxdollllloxkKXOdddddddddxkO0KKKKK00    //
//    :::::;;;;;,,,,;cool:;;::codk0Ol,,,,;;;;;:::ccclllllccc::ccccccccccccccodkOOkkkkkxkkkOO0KXKK00kxdlcccccccccccclllllllllllllldkOkxdoolllldxOXKxddddddddddddxO00KKX    //
//    :::::::::::::::looc;;;;:coxO0kl:::ccloolclllllcccc::cccccccccccccccccccccoxkkkkkkkkOOO0KKOkdolcccccccccccccclllllllllllllllokOOkxdollllldkKKkddddddddddddddddxxk    //
//    ::::::::::::c:codl:;,;;:ldk00OxxxkkO0X0ocllcccc:cccccccccccccccccccccccccldkkkkkOOOOOO0KklcccccccccccccccccllllllllllllllllokOOkkxolcccclx0XOddddddddddddddddddd    //
//    :::::::::::::clddl:;;;:coxO000OOOOO0KNOlccccccccccccccccccccccccccccccccclxOkxkOOOOOOO0KxlccccccccccccccccllllllllllllllllloxOOkkxdlc::cldOXOddddddddddddddddddd    //
//    ::::::::::c::clddc:;;:clxO0KKK0OOO00XXxcccccccccccccccccccccccccccccccccclxOkxkOOOOOO0KKxcccccccccccccllllllllllllllllllllloxOOkkxdl::::coOKOddddddddddddddddddd    //
//    cc::::::c::::clddc:::clxO00KKXXK0O0KXKdcccccccccccccccccccccccccccccccccclxOkxxkOOOOO0KKxcccccccccccllllllllllllllllllllllloxkkkkxdl:;;;:lkKkooddddddddddddddxxx    //
//    cccccc::cccc:coxdlccloxO0000KKXNNK0KN0occccccccccccccccccccccccccccccccccokOOkxkkOOOO0KKdcccccccclllllllllllllllllllllllllloxkxkkxdoc;,;:lOKxoooddddddddxxxxxxkk    //
//    ccccccccccccccoxdooodxkO0000O00XNWXXNOlccccccccccccccccccccccccccccccccccokOOOkkkOOOOO00dcccccclllllllllllllllllllllllllllloxkkkkxxdl:;;:o0Kdoooodddxxxxxxkkkkkk    //
//    cccccccccccccclddooxkkkOOOOkkkkO0XNWNklccccccccccccccccccccccccccccccccccdkOOOkkOOOOOOK0dccllcclllllllllllllllllllllllllllloxkkkkkkxdc;:cxKOooooodxxkxkkkkkkkkkk    //
//    ccccccccccccccccccldkkkkOOkkxddddxOKNXOdlcccccccccccccccccccccccccccccccldkOOOOOOOO0OOK0dccllllllllllllllllllllllllllllllllodxddxkkkxoccoOXOoooooodxkkkkkkkkkkkk    //
//    cccccccccc:ccccccclxkkOOOkOkxdoollodk0XXOdlcccccccccccccccccccccccccccccldkOOOOkkOOOOOK0occlllllllllllllllllllllllllllllllooolodkkOOOxlldOKOdoooooodxkkkkkkkkkkk    //
//    cccccccccc:::cccccokkkOOOkkkkkdolccclodk0K0xolcccccccccccccccccccccccccclxOOOOkkkkOOO0X0occlllllllllllllllllllllllllllllollclodxkkOO0OkxkO0Odoooooooodkkkkkkkkkk    //
//    ccccccccccccccccccdkkOOOOkkkOOkdoc::::clldkOOkxdolcccccccccccccccccccccclxOOOOkkkOOOO0X0ocllllllllllllllllllllllllllllllc::lodddxxkO0KK0O0K0dooooooooodxkkkkkOkk    //
//    cccccccccccccclccldkkOOOOOkkOOOOxoc::::::cccldxxxddooollccccccccccccccccoxOOkkkOOOOOO0XOollllllllllllllllllllllllllolc:;;cllloodxkO000OO00K0xoooooooooodxkOOOOOO    //
//    ccccccccccccccllllodxOOOOxxkOOO00kdc:;;;;:::::::::ccclllllllllllccccccccokkkkkkOOOOOO0XOlllllllllllllllllllloooollc:;,;:cccclloxkO0OOOOO0000xooooooooooodxkOOOOO    //
//    ccccccccccccccclllllldkkddxkOO00KX0dc;;;;;;:::::;;;,,'''',,;;:cccllllllldkkkkkkOO000O0XOlllllllllllllllllcc::;;,,''',;:::::clokOOkkOOOOO000KkoooooooddooodxkOOkk    //
//    ccccccccccccccccloolllllldkkOO00KNNkoc;,;;;;::::::::;;;,,,''.....'',,;;:codddxxkOOOOO0Kklllcccc::;;;,,''.......'',;;::;;;;:cdkOOkkkOOOOO000Kkooooodddoooooodxxxx    //
//    ccccccccccccccccoxdolllllodxk000XNXdodl:;;;:::::cllcc::::;;;;;,,'''.........'',,;;;;;;;,''.............''',,,;;;:::::;;;;;cdkOOkkkkkOOOO000KOoooddddooooodddddxx    //
//    cccccccccccccccldkkoloollllloxO0XN0oclddc::::clodddddddoolc:::;;;;;,,,,,,''................'''',,,,,;;;;;;;::::::::;;;;;;cxxxkOkkkkkOOOO00OOxooxxxdooooddddddddd    //
//    ccccccccccccccclxxc;;cooolllcloxKNOlcclxxolcllolllllloodddddooollc:;;,,,,,;;;;,,,,,,,,,,,,,,,,;;;;;;:::ccllooooolc::;;;:lxxddkkkkkkkkOOOkxdoooxxdooodddddddddddd    //
//    cccccccccccccccll:,,,;ldolllclodxkdlccclddollllllllllllllllllooodoooolc:;,,,,,,;;;;;,,,,,,;;:ccllooodddddddddddxxdoc::coxxdodkOOOkkkxxxdoooodxxdoooddddddddddddd    //
//    cccccccccccccc:;,,',;:okxolllllllllcccllllllllllllllllllllllllllllllooodol:;;,,,,,,,,,;:clooddddooooooollllllooooodddodxdooodxOOOOkxddoooookOxdodddddddddddddddd    //
//    ccccccccccccc;,'''',:lxOOxolllllccccclccllllllllllccclllllllllllllllllldkkxoc;,,,,',;codddolllllllllllllllooooooooooddxdoooodxkkxddooolloxO00xoddddddddddddddddd    //
//    ccccccccccc:;,'''',;cok0OOkdolllccccc::ccclllllllc:::lllllllllllllllllldkkkkxo:,,,;cdO0dllllllllllllllloooooooooooooooooooooddxdolc:ccldO00O0kdddddddddddddddddd    //
//    llcccccccc;,''''',;:ldOOOOOOxolcccccccccccccllllc::;;cllllllllllllllllldkkkkOOxlcldkOK0dllllllllllllloooooddoooooooooooooooollooddoodxO00OO00kdddddddddddddddddd    //
//    lcllcllc:,''''''';:clxOOOOOO0koccccllllllcllcllcc:::;:lllllllllllllllloxkkkkkO0OkOOO0K0dlllllllllloooooooodddooooooooooollccccclloodk000OOOO0kdddddddddddddddddd    //
//    lllllc:;,''''''',:ccdkOOOOO000Oxllclllllllllllccccc:;;cllllllllllllllloxkkkkOO0OOOOO0KOollllllllooooooodddddddooooooollcccclllloodxO00OOOOOO0kdddddddddddddddddd    //
//    olllc;,'''''''',;:clxkOOOOO000XKkdollllllolllccllllc;,:llllllllllllllloxkkkkOO0OOO000KOolllllooooddddddodddddddooooolllloooooooodk00OOOOOOOOOOdddddddddddddddddd    //
//    Okoc,'''''''''';::cokkkOOO00KKXXkxddoolollolllllcllllc:clllllllllllooloxkkkOOOOOOO000KOoooooooodddddddollodddddooolllooooooooodkO0OOOOOOOOOOOOxddddddddddddddddd    //
//    Oxc,'''''''''';:ccldkkkOkO00KXNKdodxdooooooolllcllllollllollollloooooodkOkkOOOOOOOO00KOooooodddddddddddl;:odddoooolooooooooddxOK0OkOOOOOOOOOOOxddddddddddddddddd    //
//    o;''''''''''',:cccoxkkkkkO00KXN0dlodxdddooooolccloooollloolloooooooooodkkkkOOkOOOO000Kkoooooodddddddddddc,coooooooooollloodxk00OkkOOOOOkOOOOOOxddddddddddddddddd    //
//    ,''''''''''',:cccldkkkkOO000KXXOoooodxxddoooolllooooollooolloooooooooodkkkkOkOOOOO000Kkoooooooddddddddoolclooooollllllooodk0K0OkkOOOOOkkOOOOOOkddddddddddddddddx    //
//    '''''''''''':ccccokkkkOOO00KKXXkoooooddxdoooolloolllllloollllloooooooodkkkkOkOOOOO000Kkoooooooooddddolllllloooollllllooodk00OkkOOOOOOOkkOOOOOOkdddddddddddddddxx    //
//    ''''''''..';clllldkkkOOO000KXNKxooooooodxdoooloolllccccllcc::cccllooooxkkkOOOOOOO00000kooooooooooooolllooooodooolllllodx0K0kddkOOOOOOOkkOOOOOOkddddddddddddddxxk    //
//    '''''....',clllloxkkOOO0000KXN0doooooooloxddoooollllcclllcclllllllooolxOkkOOO00OO00000xooooooooodoolollloooodooooddddxO0KOxdddkOOOkkkOkkOOOOOOkxddddddddddddxxkk    //
//    ''''.....,cllllldkkkOO0000KKXXOoooooool::ldddooolloolloollllooolloddoldkkkkkO000O000K0xooooooooodooololllooodddooddxk0K0kxddddkOOOkkkOkkOOOOOOkxdddddddddddxxxkk    //
//    ........':lollloxkkkO00000KXNXkooooool:;;:lddddoooollooollooolloddddollodxkOO00OO000K0xooolllloodooolloolododdddddk0KK0kkxxxxxkOOOkOOOkkkOOOOOOxddddddddxxxxxkkk    //
//    .......':looolodkkkOO0000KKXNKxoooool:;;;::cddddoollcclolloollodxdoollloooodxO000000K0dllllllooodoooolooooodddddxOKK0xxkkkkkkkOOOOkkOOOkkOOOO0Oxdddddddxxxxxkkkk    //
//    .......;looooodxkkOOO0000KKXN0dooool:;;;;:::codddoolcllollllodxddoollloollclooxOOOOkxdollllllooodooooooooooddddk0KKkc';okkkkkkOOOOkOOOkkkOOOOOOkdxxxxxxxxxxkkkkk    //
//    ......,loooooodkkOOO000000KXXOdooolc;;;;;::::codxxdollooooddxddoolllooollllol:codxdocclllllclooodooooollooodxxO0K0d;...'cdkkxxkOOkkkOOkkkOOOOOOkxxxxxxxxxxkkkkkk    //
//    .....'coooooodxkOOOO000000XNXkooooc;;;;;;;::::cldxddddddooollccllloooollllol::looooolccllolllloddoooooolooodk0KKOl'......,lxxxkOOkkkOOkkOOOOO00kxxxxxxxxxxkkkkkk    //
//    ....':oddooooxkkOOOO000OO0KNKxodoc;;;;;;;;::::::ldxxxdllccccccccclllllloool:;clllloollcccloooooddoooooooodkOKKKk:.........':dxkOOkkkkkkkOOOOO00kxxxxxxxxxkkkkkkk    //
//    ....;odddddodkkkOOOO00000KXX0ddoc;;;;;;;;;;;:::::ldxxxdocc::::::ccllllollc;;clollclolcccccclooodddoodoodxO0KK00x;...........,lkOOkxxkOOkOOOOOO0Oxxxxxxxxkkkkkkkk    //
//    ...,ldddddddxOkkOOO000000KXXOdoc;;;;;;;;;;;:::::::coxxxdollllllllc:cccc:;;:llloollcclllccccccloddddodddxOKKK0000o'...........'cxOkkkOOOOOOOOOO0Oxxxxxxxkkkkkkkkk    //
//    ..'ldddddddxkOkOOO000000KXNXkdl;;;;;;;;;;;:::::::::coxxxxxollccc:::;;;;;:clllcloolcccclllllllodxdddodkOKKK000000Oc.............;okkkOOOOOOOOOO0OxxxxxxkkkkkkkkOO    //
//    ..cddddddddkOOkOO0000000KXNKxl;,,;;;;;;;;;::::::::::coxxxxxdoooolllccc::::c:::llllcc:::ccllllodxddddk0KXKOxO00000x;.............'cxkOOOOkOOOOO0OkxxxxkkkkkkkOOOO    //
//    .:dxddddddxkOOOOO000O000KXN0o;,,,;;;;;;;;;:::::::::::cldxxdocc:::::::::ccccllcloollcclllllllloodddodOKK0kdox0K0000o'..............,lkOOkkkkOOO00kxxxkkkkkOOOOOOO    //
//    ,oxxxxxxddkOOOOOO00OOO00KNXx:,,,,;;;;;;;;;::::::::::c:clodddddollccc::;;::clooooolllllllooloddddxdooxOOxooldOK0000k:................:xOOkkkkOO00kxxkkOOOOOOOOOOO    //
//    lxxxxxxxxxkOOOOOO00OO000XNOc,,,,,,;;;;;;;;;::::::::::clodddddxxxxxdddolc:;;:lodooloollcldddxdoodxxxxxxxoolcckK0KK00d,................,okkkkkOO00kxkkOOOOOOOOOOOO    //
//    xxxxxxxxxkOOOOOO00OO000KXO:'',,,,,;;;;;;;;;::::::::ccodxkkkkkxxxxxxxddddoc;,:oddooolccloddoooodxxddxxxxxdl;:x000000Ol'.................:dkkkOO00OkkOOOOOOOOOOOOO    //
//    xxxxxxxxxkOOOOOO0OOO0000x:''',,,,,;;;;;;;;;:::::::clodddddxxdxxxxxxxxddoooc;:lddolcccccloolllodxdddodxxxxo;;d0000000x:..................,lxkkOO0OkOOOOOOOOOOOOOO    //
//    xxxxxxxxxkOOkOO00OO0000d;'''',,,,;;;;;;;;;::::::clooddddoooooooooooollllllllllolc:::::cclolllooddddoooodxdl:lOK000000o,...................:dOOO00OOOOOOOOOOOOOOO    //
//    kkxxxxxxkkOkOO00O0000Oo;'''''',,,;;;;;;;;;;::::lxkxxxddddddddddddooooooolllccldolccclclloolcccldxdooddxxxddodO0000000Oc'...................,lkO00OOOOOOOOOOOOOOO    //
//    kkkkxxxkkkOOOO0OO000Oo,''''''',,,;;;;;;;;;:::ldk0OkOkkxxxxddddddddxdddddooddooxdoc;::cloddooolldxddxxkxdoodxOO0K000000x;.....................:x000OOOOOOOOOOOOOO    //
//    kkkkkkkkOOOOO0OO000Ol,'''''''',,,;;;;;;;;::cokO00OkkOOOkkkkxxxxdddddxxxxdodxddxkxdlc:::oxxooooodddxxxxdddxkkxxk0000000Oo,.....................,oO0OOOOOOOOOO0000    //
//    kkkkkkkkOOOOO0OO00Ol,''''''''',,,,;;;;;;:coxOOO00OkkOOkkkxxxxxxdddddddxxxdodxxkkxdddolloxxoooooxxxxxddoddddddxkkO000000kc'......................:xO0000000000000    //
//    kkkkkkkkkOOO00000kl,''''''''''',,;;;;;;:lxOOOOOOOOOkkOOkkkkkkkkkkxxxxxxxkxdoxkkkxxxddddxkdlooddxxxxdoooooodxxkkkkO000000d;''.'...................'lk000000000000    //
//    kkkkkkOkkOOO0000kc,'''''''''''',,,;;;:lxOOOOOOOOOOOOkkkkkkkkkkkkkkxxkkddxkxxkOOkkkxxddxxkxoodddxxxddooxxdddxkkkkOOOO0000Ol'''''''..................;dO0000000000    //
//    kkkkkkOOOOO0000xc,''''''''''''',,,;;cdO00OOOOOkOOOOOkkkkkkkkkxkkkxxxkkxxkOOOOOOOOOkkxxdxOkdoddxxxxdoodxxxxxxkOOkOkxdk0000k:'''''''''................'lk000000000    //
//    kkkkkOOOOOO00Ox:,''''''''''''''',;:okO00OOO0OOOkOOOOOkkxkkkkkxxkxdxkkkkOOOOO0000OOOOOkkkkkxddxxkkdooodxddxxxkOOOkxxkOO0000d,'''''''''''...............;d00000000    //
//    OkkkOOOOOO00Ox:''''''''''''''''';lkOOOkkkkkkkOkkkxxxxxxddddddddddxkOOOOO0000OxxO0000OOOOOkxxxxkkkdoddddddxxkkkOOkxkOOOO000Ol,'''''''''''...............'lk000000    //
//    OOOOOOOkOO0Od:'''''''''''''''',:oxkxxxdddddddddxxxddddooooddooddxkOOOO000kxl:;;:loxO00OOOOkkkxkkkxxxxdddxxxxkkkOkkOkkOOOO00x:'''''''''''''...............;x00000    //
//    OOOOOOOOOOOd;'''''''''''''',,cdkOOkkxxxxxxxkkkkkxxxxxxxxxxxxxkkOOOO000kdl:;,,,,,,,;cokO00OOOOkOkkxkxdxxxxxxxxkkkkkkkkOOOOO0Oo,''''''''''''''..............'lO000    //
//    OOOOOOOOOko;''''''''''',,;cldkO0OOOOOOOOOOOOOOOkkOOkkkxxkkOOOOOO000kdl:;,,,,,,,,,,,,,:ldk000OOOOkkkxxxkkxxxxxkkkkkkkOOkkOOO0kc,'''''''''''''''.............':x0K    //
//    OOOOkxxdoc,'''',,'',;:codkO000OOOOOOOOOOOOkkkkOOkkkkkkkkkOOO000Okdl:;,,,,,,,,,,,,,,,,,,;:lxO00OOOOkkkkOkxxxxxkkkOkkOkkkkOO0OOd;'''''''''''''''..............';oO    //
//    olcc:;,,,'''''',;cloxkOOO000000OOOOOOOOOOkkOkkkkkkkkkOOOO000Okdl:;,,,,,,,,,,,,,,,,,,;cc;;,;:oxO00OOOOOOOkkkkkkkkkkkkkkkOOOOOOkd:,''''''''''''''.............',;c    //
//    ,,'''''''',;:codxOOOOOOOOOOOOOOOOOOkkkkkkkkkkkkkkkOOOO000Okdc:;,,,,,,,,,,,,,,,,,,,,;lkkdolc:;;cokO00OOOOkkkkkkkOOkkkkkkOOOkOOOOkl;''''''''''''''............',,;    //
//    ''''',,;cldxkOOOOOkxdkkkkkkkkkkkkkkkkxxxxxxxxxkOOOO000Okoc;;,,,,,,,,,,,,,,,,,,,,,,,:x00Oxdddolc:cldk00OOOOOkkkkOOOOkkkkOkkOOOOOOOd:,''''''''''''...........'',,;    //
//    ',,:codkOOOOOOOkdlldkOkkOOOkkkkkkkkkkkkkkkkkkOOO000Oxoc;,,,,,;,,,,,,,,,,,,,,,,,,,,;oO000OxdddddddoooxkO00OOOOOOOOOOkkkkkkOOOOO0000kc,'''''''''''...........'',,;    //
//    ldxkOOOOOOOOOxo::okOOOO0OOOOOOOkkkkkkkkkkkOOO000Oxoc;;,,;,,,,,,,,,,,,,,,,,,,,,,,,,ck00000OkdddddddddddxkO000OOOOOOOOkkkkOOOOO000OOOko;''''''''''...........'',,;    //
//    OOOOOO000Okoc;;lxOOO00OOOOOOOOOOOkkkkkkOO0000Oxoc;;;;;;;;,,,,,,,,,,,,,,,,,,,,,,,,;oO0000000kxdddddddddddxxkO0O00OOOOOOkOOkkkOOOOOOOOOxc,''''''''...........'',,;    //
//    OOO00OOkdc;,;cxkkO00OOOOOOOOOOOOOkkkOOO000Oxoc:;::::::;;;;;,,,,,,,,,,,,,,,,,,,,,;ck000000000kxddddddddddddxkOOO0000OOOOOOOOOOOOOOOOOO0ko;'''''''...........',,;;    //
//    O0O0Odl:,',cdOOkO00OOOOOOOOOOOOOOOOO0OOOkdlccccllcc:;;;;;,,,,,,,,,,,,,,,,,,,,,;:cd0000000000OOxddddddddddddxOOOOO000000OOOOOOOOOOOOOOOOOd:'''''............',,;;    //
//    0Oxo:,,',:dO0OOOOOOOOOOOOOOOOOOOkkxxdoollclllccc:;;;::::ccc:;,,,,,,,,,,,,,,,,,;lxO00000000000OOxdddddddddddxOOOOOOOO0000000OOOOOOOOOOOOOOkl,'''...........'',,;;    //
//    oc;,'',:ok00OOkOOOOOOOO0OOOOkxdolccccccllooollcllllooodddl:;,,,,,,,,,,,,,,,,,,:x000000000000OOOOxdddddddddddxOOOOOOOOOOO00000OOOOOOOOO00O0Odc;,,'''.......'',,;;    //
//    c:;,,;lkOOO0OkkOOOOOO000Okxdlccccccloddddddddddddddxxxdl:,,,,,,,,,,,,,,,,,,,,;lO0000000000000OOOOkdddddddddddkOOOOOOOOOOOOO00OOOOOOOOOOOOOOOkoc::::;;,''.'',,;;;    //
//    0OkxxxkO00OOOkkOOOO000Oxdlccccllodxxxxdddddddddxxkkkxoc:;;;,,;;;;,,;::::;;,,,:x00000000000000OOOOOkddddddddddxOOOOOOOOkkkkOOO0OOOOkkkkkkOOOOOkdl:ccccccccc:::;;;    //
//    xxkOOOkOO00OOOkOOO0OxolccccoodxxxxddddddddxxkkOOkkxdddoolc::::;,,'',;::cllolldk0000000000000OOOOOOOkxdddddddddkOOOOOOOOkkkkkkkOOOOOOOOOOOOOOOOOxoc::::::ccclllll    //
//    dxkOOkkOOO0OOkkOkxdlccloddxxxxddddddddxxkOOOOOkxdoolllccc:::;;,'''''''',,;clodxxkkkkkOOOOOOOOOOOOOOOkxddddddddxOOOOOOOOkkkkkkkkkkOOO00OOOOOOOOOOkdc::::::::::ccc    //
//    kOOOOkkOOOOOOkxolcloddxxxxdddddddxxkkOOOOOOkxdolcccccc::::;,,''''''''''''',,,;:llodxxxxkkkkkkkOOOOOOOkxdddddddxkOOOOOOOOkkkkkkkkkkkkOO00OOOOOO00OOxoc:::::::::::    //
//    0OOOOOkOOOOxdllodxxxxxddddd                                                                                                                                         //
//                                                                                                                                                                        //
//                                                                                                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract AKR is ERC721Creator {
    constructor() ERC721Creator("A KNIGHT RENDS", "AKR") {}
}