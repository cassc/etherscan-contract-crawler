// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Editions by Mayank
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                        //
//                                                                                                                        //
//    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////    //
//    //                                                                                                            //    //
//    //                                                                                                            //    //
//    //                                                                                                            //    //
//    //                                                                                                            //    //
//    //    .''''''',:od:.'''',;:lxOOOOO000000OOOOO00OOO000OOOOO000000OOOkkkkxxxxxxxxxxxxxxddddddddddddddddddddd    //    //
//    //    '..''''''',cc'.'''',,;lkOOOOO0OOOOOOOOOOOOkkkkkkkkkkkkkkxxxxddooddoooooooooooooooooooooooooooooooodd    //    //
//    //    ...''''''''''..''''',,cdOO0OOOOOOOOOkkkkkdooooooollll::::::cc:;;;:cllllllclllllllllllllllllllllllloo    //    //
//    //    ....'''''.......'''',,;okOOOOOOOOOkxxxolc;,,;;,,''.....'''''''',,,,;;::::::::::::::::::::ccccccccccl    //    //
//    //    ....''''........'''',,;cxOOOOOOOOkxol:;,'......................',;,....;cllllcclllllllllcccc::;;;;;:    //    //
//    //    ',,,,,;clollc:;,;;::cllox0000000ko:,'............................''.....cxkOOOkOOOOOxdxO000Okxkdoolc    //    //
//    //    dddddddxk0XKK0000O0000KKKKKKK0Kk:'...........'',,,,;;;;;;;;;;,,'.........:xO0O0KKKKK0xodO0KK0KXKKKKK    //    //
//    //    dddddxddx0KKKK00KKXKK00KXK0O0Oo,.........,;:ccllooooddddddddooool:;'......'ldxkkkkkkOOOxdxO00KKO0KKK    //    //
//    //    odddddddxKXKKKKKKKK00KKKKKK0d;'......';:clooddxxxxkkkkOOOO00OOOkxdol:,.....'ldooxdoooxxllooddOK0O0KK    //    //
//    //    dodddddokKXXKKKKXXKKKXK00K0d,.......;clloodddxxkkkkOOO000KKKKKK00Okxdo:'....;lodkkxdoxxdolcc:cdxOOxc    //    //
//    //    doddooodkOOOO00KKKKKKKKKK00o,.....';clloodddxxkkkOOOOOO00000KKKK0OOkkxdl,....cxxxxdodxoodlllcllllc'.    //    //
//    //    doddooolx0OkxkkkxkkkOO0OkOkc'....';ccllooodddxkkkOOOOO000000KKK00OOOkkkxo;...,okkkxxOkdddolloocc;'..    //    //
//    //    ooooooolxKKK0K0kkO0K0OkxkOd,.....';:cllooodddxxkkOOO00000000000000OOkkkxxo;...lOOOOOkxdooolccc,'...'    //    //
//    //    llooooooOKKKKKKK00KKXK0kkOd'.....',:clooooddxxkkOO00000000000KKKK0OOkkkkxdc,.'d0Oxkkdoddcldl::,.....    //    //
//    //    oollooooOKKKKKKKKOO000OOO0d'......,;clloooddxkkOO0000KKKK000KKKKK0OOOkkkxdc,.;x0OOOOOkkxodoc;'......    //    //
//    //    olllloooOKKKKX0OKKOOOOO00x:.......,:clloodddxxkOOO00000000000000000OOkkkkxl'.;k00kkOOdodoc;'........    //    //
//    //    lllllllo0KKKKK000KK0O0KOdoc'.....,:cccc:;;;::ccloddxkOOOOOOOOOxddxxxxxddddl;.;okOkkOdlcll;..........    //    //
//    //    llllllloOKKKKKKKK0KKKK0xolc'....':c:;,''''''',;:cc:codxkxxxdolc::cccloc:clc;,,,lO0kdddo:,'..........    //    //
//    //    llllllld0KKKKK0O000OO0kddo:'..';;'''',;ccclllcldOOxdoc;,,,'';ldollllooddolc::,;xKOolddo;'...........    //    //
//    //    llllllld0K0K00O0K0kxxxkdcll;...';,..,:::::clollllooooc'';;'.;lollodxxxxxddlll:lO0klclo:'.'..........    //    //
//    //    llllllld0K0000KKOOOOkxdxococ'..':c;';c:;,;;::::::::cc:,:dxl,;c::::clllccldolccxkddc,,,..............    //    //
//    //    llllllld00000K0OOO0OOxdddlc:,..,clc;;c:;,,;;;;:::ccc:,;oOOOl,:lccccclllloddl:lolc,..................    //    //
//    //    llllllld000000OkO000Okxolooc,..,cllc:clcc:cccllllooo:,lxO00Oxllodooddxkkkxoodl;'....................    //    //
//    //    lllllllk0000000OkOOOkkxoloo;,'.;lloolllooodddxxxdolc:ldkO0000Odloodxxxxdddxkkl'.....................    //    //
//    //    llcllloO00000O00kxkOkddxxxoc;;;:lloddxdodddooooollodxdxkkO000OkxodxxxkkxkOOOOc......................    //    //
//    //    clcclloO00000Ok00kddddkkxlclc;:cclodxxkkkkkkxxdoloxxxxxxxkOOOkkkdldxkO000OOOkc......................    //    //
//    //    ccccllo000OO0OOOOOkdxOkodxlcllc:cloddxkkkkkkxollllllolclodxdollddolloxxkkkkkx:......................    //    //
//    //    cccclld00OOOOO0OO0OOOkxxxxoccllccloodxxkxxxdllooollcc:::clcc::lxkdoc::ldddddo,......................    //    //
//    //    cccllcd000OO0OkkkOkkOkxkkdddlcl:clloodddddlcccllloolllllllcloodkkxoc:;;coooo:.......................    //    //
//    //    ccccclx000OOkkOOxdooxkxoxOdlclc::llooooddl::ccclloooooooooooooddoc::c:cooool,.......................    //    //
//    //    ccccclx0OO0OOOkxdxkxdxkxdxddl:,',cloooddxolll::cdxkkkkkkkkkOOkxkd::clldxddd:........................    //    //
//    //    ::ccccx0OOO0OxdxxkOOxddkxxxdl:;,',:looddxxdool:;:odkkkO0KKKX0x:;clododxxxdc'........................    //    //
//    //    ;:cccck0OOOOOxdxkOOOkdldOxlloc;'...:loddxxxddddoc::::ccloooooc:ldxxddxxdo;..........................    //    //
//    //    ;;;:coO0OOOkkOkddkkxdodxOxl:,.......;loodddxxxxddolllclllloodddxkxxxxxdl;...........................    //    //
//    //    :::::o00OOOOxxOxollloxxdol;..........,:llooddddxddddooooodddddxkkkkxxdl;...........................'    //    //
//    //    :ccc:lO0OOOkkkkxdc:llc;;,.............,;ccloodddddddddoooloodxkkkOkkdl,.............................    //    //
//    //    ::ccclk0OOkxxkdooc:,'..................,;::ccoddddxxxxxdddxkOOOOOOkxc,..............................    //    //
//    //    c::cclk0kkkxolol;'......................,;;;:clddxxxxxkkkkOOOOOOOkd:................................    //    //
//    //    xl:::cxOxdolll:'.........................';:;;;codddxxkkxxxkkkkxxo,.................................    //    //
//    //    0kl:;;oxolll:'.............................';;;;:clloodxxddooool:...................................    //    //
//    //    000x:,lxocc;'.................................',;;::ccclllcccc:,....................................    //    //
//    //    0OOOkc;;'..........................................';:cllooolc,.....................................    //    //
//    //    KOdlc;................................................,::::;'.......................................    //    //
//    //    Oc'..................................................................................';,............    //    //
//    //    c...........................................................................;lc:;;,',ld:............    //    //
//    //    '...........................................................................';clcclodkxc;,,'........    //    //
//    //    '.....'......................................................................':oddxxx00ko;,;;'......    //    //
//    //    ......'....................................................................':oododkkllOKkl,.........    //    //
//    //    ................................................................',;,....,;:ldxxOOxxkkxxdk0x:''......    //    //
//    //                                                                                                            //    //
//    //    /***                                                                                                    //    //
//    //     *                                                                                                      //    //
//    //     *                                                                                                      //    //
//    //     *                                                            `7MM                                      //    //
//    //     *                                                              MM                                      //    //
//    //     *    `7MMpMMMb.pMMMb.   ,6"Yb.`7M'   `MF',6"Yb.  `7MMpMMMb.    MM  ,MP'                                //    //
//    //     *      MM    MM    MM  8)   MM  VA   ,V 8)   MM    MM    MM    MM ;Y                                   //    //
//    //     *      MM    MM    MM   ,pm9MM   VA ,V   ,pm9MM    MM    MM    MM;Mm                                   //    //
//    //     *      MM    MM    MM  8M   MM    VVV   8M   MM    MM    MM    MM `Mb.                                 //    //
//    //     *    .JMML  JMML  JMML.`Moo9^Yo.  ,V    `Moo9^Yo..JMML  JMML..JMML. YA.                                //    //
//    //     *                                ,V                                                                    //    //
//    //     *                             OOb"                                                                     //    //
//    //     */                                                                                                     //    //
//    //                                                                                                            //    //
//    //                                                                                                            //    //
//    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////    //
//                                                                                                                        //
//                                                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MSE is ERC721Creator {
    constructor() ERC721Creator("Editions by Mayank", "MSE") {}
}