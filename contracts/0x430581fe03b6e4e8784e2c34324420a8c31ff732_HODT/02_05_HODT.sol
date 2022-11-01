// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: VAL SCHNACK - HERSELF AND OTHER DIFFICULT TASKS
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    kkkkOOOOOOOkkkkkkkkxxxxxxxxxxxxxxxddddddxxxxxxxxxxxxddddddddddddddddoooooooooooooooooodddddxxxxxkkkkkkkkkkOOOO000KKKKKK     //
//    dxkkkkkkkkkkkkkkkkkkxxxxxxxxxxxxxxddddddddxxxxxxxxxxdddddddddddddddddoooooooooooooooooddddddxxxxxkkkkkkkkkkOOOO0000KKKKX    //
//    dxkkkkkkkkkkkkkkkkkkxxxxxxxxxxxxxxdddddddddxxxxxxxxxdddddddddddddddddoooooooooooooooooodddddxxxxxkkkkkkkkkkOOOOO000KKKKX    //
//    odxxxkkkkkkkkkkkkkkkxxxxxxxxxxxxxxdddddddddxxxxxxxxdddddddddddddddddddooooooooooooooooddddddxxxxxkkkkkkkkkkOOOOO000KKKKX    //
//    odxxxkkkkkkkkkkkkkkkxxxxxxxxxxxxxdddddddddxxxxxxxxxdddddddddddddddddddddoooooooooooodddoddddxxxxkkkkkkkkkkkOOOOO000KKKKX    //
//    odxxxxkkkkkkkkkkkkkkkxxxxxxxxxxxxxxddxxxxxxxxxxxxxxxxddddddddddddddddddddoooooooooooooooddddxxxxkkkkkkkkkkOOOOO0000KKKKX    //
//    oddxxxxxkkkkkkkkkkkkkkkxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxddddddddddddddddddddddooool:lododdddxxxxxkkkkkkkkkkOOOOO0000KKKKX    //
//    oddxxxxxxxkkkkxxxxxxxkxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdddddddddddddddddddddddddd:.'lddddddxxxxxkkkkkkkkkkOOOO00000KKKKX    //
//    oddxxxxxxxxkkxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdddddddddddddddddddddddddddolloddddddxxxxxkkkkkkkkkOOOOO0000KKKKKX    //
//    oddxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxddddddddddddddddddddddddddddddddddddxxxxkkkkkkkkkkOOOOO0000KKKKKX    //
//    odddxxxxxxxxxxxxxdodxxxxxxxkxxxxxxxxxxxxxxxxxxxxxxxxxxxxdddddddddddddddddddddddddoodddddddxxxxxkkkkkkkkkkOOOOO0000KKKKKX    //
//    oddddxxxxxxxxxxxxdoodxxxxxxkkkxxxxxxxxxxxxxxxxxxxxxxxxxxddddddddddddddddddddddddddodddddddxxxxxkkkkkkkkkkOOOOO0000KKKKKX    //
//    oodddxxxxxxxxxxxdlloddxxxxkkkxkkxxxxxxkxxxxxxxxxxxxxxdxxddddddddddddddddddddddddddodddddddxxxxkkkkkkkkkkkOOOOO0000KKKKKK    //
//    oodddxxxxxxxxxd:;:coddxxxkkkkkkkkkkkkkkkkkxxxxxxxxxxxxxxddddddddddddddddddddddddddddddddddxxxxkkkkkkkkkOOOOOOO0000KKKKKK    //
//    oodddxxxxxxxxx:..c:ldc::lkkkkkkxxkkkkkkkkkkkxxxxxxxxxxxxxxdddddddddxxdxdolc;,''';oddddddddxxxxkkkkkkkkkOOOOOO00000KKKKKX    //
//    oodddxxxxxxkdo:.,ddxd;..;kkkkxddxkkkkkkkkkkkkxxdollloxxxxxxxxxxdxo;:odl,....',;:codddddddxxxxxkkkkkkkkOOOOOOO00000KKKKKX    //
//    oodddxxxxxxxdo,.:xkko,. :kkd:cdxxkkxlllcclxkxl''',,;;cl:;:;;;;ldd:..cc..,.'ldxxdddddddddddxxxkkxxkkkOOOOOOOOO0000KKKKKXX    //
//    oodddxxxxxkxd:..okkkl'. cxd;...'':dc..',,.,dx,.cxkkkc..  .',;;lxo' 'ododc. ;ddoollooddddddxxxkkxxkkkOOOOOOOO00000KKKKKXX    //
//    ooddddxxxdl:,. .:lc:.  .cc'....;odl. ;ddc.,dko,;dkkkd;..:dddoddx:..:dddo,  .'..',:lddddddxxxxxkkkkkOOOOOOOO000000KKKKKXX    //
//    lodddddxxl,.    ....   .;dc.,llxkko'.',,,cxkkkd:';oxx,  .....;dd' .lxxl,.  .,;codddddddddxxxxxkkkkkOOOOOOOO00000KKKKKXXX    //
//    loddddddddl,.  .,:::,. .,o:.';:;cxd'  .',;;:::cdd;';l' .;cloodxl..,oxxxl. 'oxddddddddddddxxxxxkkkkkOOOOOOO00000KKKKKKXXX    //
//    looddddxddxc. .cxxkd;. 'o:.  .':okx,.;c::;;;,,;oxx:.',..:lclodxl. ;dxxdl. ;odddddddddddddxxxxxkkkkkOOOOOOO00000KKKKKKXXX    //
//    looddddddxd:. .okxkd:. ,dl...,:::lo:cxkkkkkkd:,,,'.,col;,',cddxo, .;:;::..cdddddddddddddxxxxxkkkkkkOOOOOOO00000KKKKKXXXX    //
//    looddddddddc'.,dxxxxxlloxxc...,;cdkxkkkkkkxkxollloddxxxxxxxxxxdddl;,',collddddddddddddddxxxxxkkkkkkOOOOOOO0000KKKKKKXXXX    //
//    loooddddddxdoodxxxxxc,lxxxxl;okkkkkkkkkkkkkxxxxxxxxxxxxxxxxxxxxdddxxxxddddddddddddddddddxxxxxkkkkkOOOOOOOO0000KKKKKKXXXX    //
//    looooddddddddxxxxxxxlldxxxxxdxkkkkkkkkkkkxxxxxxxxxxxxxxxxxxxxxxxdddddddddddddddddddddddxxxxxxkkkkkOOOOOOOO000KKKKKKXXXXX    //
//    lloooooddddddddddxxxxdxxxxxxxxxxkkkkxxkxxxxxxxxxxxxxxxxxxxxxxxxxxxxdddddddddddddddddddxxxxxxkkkkkkOOOOOOO0000KKKKKKXXXXX    //
//    lloooooodddddddddddxxdxxxxxxxxxxxxxxxxxkxxxxxxxxxxxxxdxxxxxxxxxxxxxxdddddddddddddddddxxxxxxxkkkkkkOOOOOOO0000KKKKKXXXXXN    //
//    llooooooooodddddddddddddxxxxxxxxxxxxxxxxxoc;lxlcdxxko,';;coxxxxxxxxxxxxddddddddddddddxxxxxxkkkkkkOOOOOOOO0000KKKKKXXXXNN    //
//    llooooooooooodddddddddddddxxxxxxxxxxxxxxx; ,dd;.:kxxo..,...';cdxxxxxxxxxdddddddddddxxxxxxxkkkkkkOOOOOOOO00000KKKKKXXXXNN    //
//    lllooooooooooooodddddddddddxxxxxxxxxxxxxo' .,'. 'dxxx:,c.'l:'.,oxxxxxxxxxxxxxxxxxxxxxxxxxkkkkkkOOOOOOOO00000KKKKKXXXXXXN    //
//    llllloooooooooooooodddddddddxxxxxxxxxxoc....;ol..cxxk:,c.;xol,.cxxxxxxxxxxxxxxxxxxxxxxxxkkkkkkOOOOOOOO00000KKKKKKXXXXXXN    //
//    clllllooooooooooooooodddddddxxxxxxxxo;'. ;l,:xl. .lxx;;l..'..'cdxxxxxxxxxxxxxxxxxxxxxxxkkkkkkOkOOOOOOOO0000KKKKKKXXXXXXN    //
//    cllllllooooooooooooooooddddddxxdxxdxolc.'dxllxd;;c;c:':l,,:odxxxxxxxxxxxxxxxxxxxxxxxxxkkkkkkkkOOOOOOOO00000KKKKKKXXXXXXN    //
//    cllllllllooooooooooooooodddddddxxddxxxdclxxxxxxxxxdc;:dxxxxxxxxxxxxxxxxxxxxxxxxxkkxkkkkkOOkkddkOOO00000000KKKKKKXXXXXXNN    //
//    cllllllllllooooooooooooodddddddddddxxxddxdddxdddxxdxxxxxxxxxxxdodxxdollccccldxddkkxdlc:lxkc'';;oO00000000KKKKKKXXXXXXNNN    //
//    clllllllllllooooooooooooddddddddddddddddddddddddddxxxxxxxxxxxd,.;::;'...';,.;o,,dl...,:ox: .dO:.o0O000000KKKKKXXXXXXXNNN    //
//    ccllllllllllllllooooooooodddddddddddddddddddddddddddxxxxdxxdd;.;dd:;do.,xOd..c.....:dxkOd. ;o:.'d0O000000KKKKXXXXXXXXNNN    //
//    ccclllllllllllllllooooooooodddddddddddddddddddddddddddddxxxl;.'oxxo,ll.,xx; .. .. .,,;ok:    .:oxkkkO00KKKKKKXXXXXXXNNNN    //
//    ccclllllllllllllllllooooooodddddoooooooddddddddddddddddddxx;..;xxxo,ll.,kx; ,;.''.:ooxOx' .,,,;,,,,ck00KKKKKXXXXXXXXNNNN    //
//    ccccclllllllllllllllllooooooooooooooooooooodddddddddddddddd, .cxdx:'ol.,kx; cc.,,.cOkkkd..oOOkkxxxxkO000KKKKXXXXXXXXXNNN    //
//    cccccclllllllllllllllloooooooooooooooooooooooddddddddddddddc'.,oo;.:xl.;xx:.ll,oo.'ol:do.;kOOOOO000000KKKKKXXXXXXXXXNNNN    //
//    cccccccllllllllllllllloooooooooooooooooooooooodddddddddddddddc;;;;ldxd:lkkddxxxkkd::cokkdkOOOO0000000KKKKXXXXXXXXXXNNNNN    //
//    ccccccccllllllllllllllooooooooooooooooooooooooodddddddddddxddddddxxxxxxxxxxkkkkkkkkkOOOOOOO000000000KKKKXXXXXXXXXXNNNNNN    //
//    cccccccccccclllllllllooooooooooooooooooooooooooooddoddddddddddddxxxxxxxxxkkkkkkkkkkkOOOOOOO00000000KKKKKKXXXXXXXXXXNNNNN    //
//    :cccccccccccllllllllllooooooooooooooooooooooooooodooodddddddddddxxxxxxxkkkkkkkkkkkkOOOOOkkkxxk000KKKKKKKKXXXXXXXXXXNNNNN    //
//    :ccccccccccccllllllc:,,,;:colc;,,,;cloooolloolc:;:lodoollcldxxdoooxxxkkxxkkkdccdkkkOxc;,.';:cdO00KKKKKKKXXXXXXXXXXXNNNNN    //
//    ::cccccccccccccclc'....  .,c:. .,:cl:,'''',''.'',;ll:'..',cdxo;,;cdxo:cxkkkxc..lOOOOkol:..cO00000KKKKKKXXXXXXXXXXXNNNNNN    //
//    ::ccccccccccccclc,  .,:c. .:c. .;cl;. .:clc..:oooolcc,..:dddo, ;xxxx; 'xkd,;;  cOOOO0O0x. .xK00KKKKKKKXXXXXXXXXXXNNNNNNN    //
//    ::cccccccccccccclc. .:loc. ;o, .,:l:. ';,,'  ,:;'',;lc. ,ddoc. ;xxxx' 'xx, ,; .lOOO000KO, .oKKKKKKKKKXXXXXXXXXXXXNNNNNNN    //
//    :::cccccccccccccc:. .;clc..:o; .,;:,  .',;,  ..';:oddl. 'oxdl' 'dxxx, .dl..lc .lO00OxkK0; .dKKKKKKKKKXXXXXXXXXXNNNNNNNNN    //
//    :::::ccccccccccccc. .;::..;loc..:ll:. ,loo:. ,loooodoo; 'ddxxc. ,odd:..:' ;kl  l0xc,cOKO, 'OKKKKKKKKXXXXXXXXXXXXNNNNNNNN    //
//    ::::::cccccccccc:,. .;'..:llol. ':ll' 'lloc. ,ooooodoo; .cddddl,.',:o;   ,xOl. ';';d0000l,o0KKKKKKKXXXXXXXXXXXNNNNNNNNNN    //
//    :::::::ccccccccc,    .';cl:'''',;cll,.,llll'.;ooooo:',,,:ldddddddooxxxl;cdkkxoc:lxO0O000000KKKKKKKKXXXXXXXXXXXNNNNNNNNNW    //
//    ;:::::::::cccccc:,...;ccllc::cllllllc:cllollclooooolloododddddxxxxxxxkkkkkkkOOOOOOO0O00K00KKKKKKKKXXXXXXXXXXXNNNNNNNNNNW    //
//    ;:::::::::ccccccccc:ccclllllllllllllllllllllooooooooooodddddxxdxxxxxkkkkkkOOOOOOO00O000000KKKKKKKXXXXXXXXXXXNNNNNNNNNNNW    //
//    ;;::::::::::ccccccccccccclllllllllllllllllllloooooooodddddddddxxxxxxkkkkkOOOOOOOO000000KKKKKKKKKXXXXXXXXXXXXNNNNNNNNNNNN    //
//    ;;:::::::::::ccccccccccccccclllllllllllllllllooooooooddddddddxxxxxxkkkkkOOkOOOO0O00000KKKKKKKKKXXXXXXXXXXXXNNNNNNNNNNNNN    //
//    ;;:::::::::::cccccccccccccccccccllllllllllllloooooooddddddxxxxxxxkkkkkOOOx::x0000000KKKKKKKXXXXXXXXXXXXXXXNNNNNNNNNNNNNN    //
//    ;;;:::::::::::cccccccccccccccccccllllllllllllooooloddooddxxxxxxxkkkxdodxOo..x0000Odx0K0kxdolloxKNXXXXXXXXNNNNNNNNNNNNNNN    //
//    ;;;;::::::::::ccccccccccccccccccclllllllllc::;,,...'','.:dxxkkxoc:;,,,;okl.'xkoc:,..,'.'',;clloOXXXXXXXXXNNNNNNNNNNNNNNN    //
//    ;;;;;::::::::::ccccccccccccccccllllllllll:'..... .;clc. .:xdo:'.':ldkO00Oc ...':od,.'lxO0KXXXXXXXXXXXXNNNNNNNNNNNNNNNNNN    //
//    ;;;;;;::::::::::ccccccccccccccllllllllllllcllol. 'odd,....:c'..:dkOOOOOd,. .lk0KXKd;;ldk0KXXXXXXXXNNNNNNNNNNNNNNNNNNNNNN    //
//    ;;;;;;::::::::::::cccccccccccccllllllllllllooo:. :ddc..,'  ,ooc;,;;coxko'  .,;;;::::'';::::lx0XXXNK0XNNNXNNNNNNNNNNNNNNN    //
//    ;;;;;;;;;:::::::::::cccccccccclllllllllllooooo' 'oo:. .,cc'..ckkkdl:'..ld' ,cclllooolcll;.. .;kXXKxo0NNNNNNNNNNNNNNNNNNN    //
//    ;;;;;;;;::::::::::::cccccccccclllllllllolloooc..:do' .oxxxd;.'coc;;;,,:dd..lKKKKKXXXKd;:lodxkOKXXXNNXNNNNNNNNNNNNNNNNNNN    //
//    ;;;;;;;;::::::::::::ccccccccccllllllllloooooo:.'odd, ;xxxxxxxoodoodxk00Kx..dKKKKKKXXXXXXXXXXXXXXNXXNNXNNNNNNNNNNNNNNNNNN    //
//    ;;;;;;;;:::::::::::::ccccccccclllllllllloooool,cdddc,lxxxxxxkkkkkOOOO000OdoOKKKKKKKXXXXXXXXXXXXXXNNNNNXNNNNNNNNNNNNNNNNW    //
//    ;;;;;;;;::::::::::::::cccccccclllllllllloooooooddddddxxxxxxkkkkkOOOOOO000000KKKKKKKKXXXXXXXXXXXXXXNNNNNNNNNNNNNNNNNNNNWW    //
//    ;;;;;;;:::::::::::::::cccccccclllllllllloooooooddddxxxxxxxkkkkkOOOOOO000000KKKKKKKKXXXXXXXXXXXXXXXNNNNNNNNNNNNNNNNNNNNWW    //
//    ;;;;;;;::::::::::::::::cccccccllllllllllooooodddddxxxxxxkkkkkOOOOOOO000000KKKKKKKKKKXXXXXXXXXXXXXXNNNNNNNNNNNNNNNNNNNNWW    //
//    ,;;;;;;::::::::::::::::cccccccclllllllllooooodddddxxxxxkkkkkOOOOOOO00000000KKKKKKKKKXXXXXXXXXXXXXXNNNNNNNNNNNNNNNNNNNWWW    //
//    ,;;;;;;;:::::::::::::::cccccccclllllllllooooooddddxxxxxkkkkOOOOOOOO000000KKKKKKKKKXXXXXXXXXXXXXXXNNNNNNNNNNNNNNNNNNNWWWW    //
//    ,;;;;;;;;;:::::::::::::ccccccccllllllllloooooddddxxxxxkkkkOOOOOOOOO00000KKKKKKKXXXXXXXXXXXXXXXXXXNNNNNNNNNNNNNNNNNNWWWWW    //
//    ,;;;;;;;;;;;:::::::::::ccccccccllllllllloooooddddxxxxkkkkkOOOOOOO0000000KKKKKKKKXXXXXXXXXXXXXXXXNNNNNNNNNNNNNNNNNWWWWWWW    //
//    ,;;;;;;;;;;;;::::::::::ccccccccllllllllloooodddddxxxxkkkkOOOOOOOO000000KKKKKKKKXXXXXXXXXXXXXXXNNNNNNNNNNNNNNNNNNNNWWWWWW    //
//    ,;;;;;;;;;;;;;;::::::::ccccccccllllllllooooodddddxxxxkkkkOOOOOOOO000000KKKKKKKKXXXXXXXXXXXXXXXNNNNNNNNNNNNNNNNWWNNWWWWWW    //
//    ,;;;;;;;;;;;;;;;:::::::ccccccccclllllloooooodddddxxxkkkkkOOOOOOO000000KKKKKKKKXXXXXXXXXXXXXXXNNNNNNNNNNNNNNNNWWWWWWWWWWN    //
//    ,;;;;;;;;;;;;;;;::::::::ccccccccllllllooooddddddxxxkkkkOOOOOOOOO0000KKKKKKKKKXXXXXXXXXXXXXXXNNNNNNNNNNNNNNWWWWWWWWWWWWWW    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract HODT is ERC721Creator {
    constructor() ERC721Creator("VAL SCHNACK - HERSELF AND OTHER DIFFICULT TASKS", "HODT") {}
}