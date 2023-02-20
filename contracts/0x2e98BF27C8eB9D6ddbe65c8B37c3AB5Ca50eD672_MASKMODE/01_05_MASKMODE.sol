// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Plato's Melon
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc:;,,'',,,;;:;;;,,,'',,;::ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccccccccccccccccccc;,''''',,;:cloddddddddolc:;,,''''',;:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccccccccccccccc;''''',:cloddxxxxxxxxxxxxxxxxxddddoc:;''..',:ccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccccccccccc:,'.',:loddddxxxxxxxxxxxxxxxxxxxxxxxxxxddddol:,'.',:cccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccccccccc;'.';ldddddxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdddddl:'..,:ccccccccccccccccccccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccccccccccccccccc:;..,codddxxxxxxxxxxxxxxxxxkkxxxxxxxxxxxxxxxxxxxxxdddddol;..,:ccccccccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccccc;..;lodddddxddxxxxxxxxxxxxxxxxkxxxxxxxxxxxxxxxxxxxddxdddddoo:'.,:ccccccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccc:..;lodddddxxd::dxxxxxxxxxxxkkkkkkkkkkkkkxxxxxxxxxxxc:oxdddddddl:..;cccccccccccccccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccccccccccccc,.'coddddddxdo,'lxxxxxkxxxxxkkkkkkkkkkkkkkkxxxxxxxxxxo,'ldddddddool,.':cccccccccccccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccccccccccc:'.,loddddxdol::',dxxxxxxkxkkkkkkkxkkkkkkkkkxkkkxxxxxxxx;';;coxddddool;..;ccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccc:. ,looddddl:',lo;;xl:oxxkkkkkkkkkxkkkkkkxkkkkkkkkkxkd::xc,oo,';lddddooo;..;cccccccccccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccccccccc;. ,loodddddol,,do,,c,,lolcloolllldkkkkkkkkxollllollloo;,c,'lx:'codddddooo;..,ccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccc;. 'looddddddoc,,l;.,oc:oo:cdxxxxd::xkkkkkkkc:dxxxxxl:ld:co;.,l;'cldddddddol, .,cccccccccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccccccc:. .cooddddddxl;.';..lxc:dlcdkxxkxl:lxkkkkkkko:cxxxxkxccdc:xo..,,',cdddddddool' .;ccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccc:. .:o:,cdddoldo,.',..cxllc:oxxxoc:cdkkkkkkkkkkdc:coxxxd:clcdl'.,'.'cdlodddl,;lc. .;cccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccc::;;;;:ccccccccc'  ;o;,,:dlll,cl,',:,,llc;,:c:;::cdxxxkkkkkkkxxxkdl::;;c:,,:ll;';,''cl,clcdc'';l:. .:cccccccc::;;;::cccccccccccccccccc    //
//    cccccccccccc:,'..     ..';:cccc;. .l:':;:d:.;,;c',;;,';,,..'',cdxxxxxxxxkkxxkkxxxxxxdl,'''.',;'';;,.::';.,dc;:';l'  ,ccccc;'..     ..',:cccccccccccccc    //
//    ccccccccc;,....,:c,..::'. .,cc:. .;l',c,:c,';:'..;;.......',;,,:cllccdxxxxxxxxdlclllc;,;,''......,:..';;',::,:;.c:. .:cc;.  .;:'.'::,....';ccccccccccc    //
//    cccccc:,...,cokOOOko,,dko,  'c,  .l:.,:;cc;'':;.... ....  .,;'.;loc:ldxxxxxxxxxl:col;.';,.  ........ ':,.;cc;;;.,l'  'c,. .lkx;'lkOOkkdc,...,:cccccccc    //
//    cccc:'..'cdOOOOOOOOOk:,dOx:. ..  ;c..:looo:.... ..,;:::;'.  .';cclddxxxxxxxxxxxxxdlcc;'.  .';;:::,'. ....,ooolc'.:;. .'  ,xOx;,xOOkOkkOOkxl,..';cccccc    //
//    cc:'..;okOOOOOOOOOOOOx;;kOk:    .,.':clool.   .,:clllllccc,. .;::;codxxxxxxxxxxdoc::c;.  .:ccllllllc;..  .:oolc:'.,.    ,xOkc,dOOOkOOkOOOOOOd:...;cccc    //
//    c:.  .',:okOOOOOOOOOOOo,lOOx'   ..'::cool'  .;cloddddddooll;. .:loodddxdxxxdddddddooc. .,clooodddddolc;.  .clol;;,..   .oOOd,cOOOkkOOOOOOkdc,'.  .:ccc    //
//    cc,',;,'..'lkOOOOOOOOOk;;kOkc.  'cl;;ooc. .'clddxxxxxxdddool:. .:looddddddddddddool:. .;llodddxxxxxkxooc,. .:lo:,cc,   ;kkOc,dOOOOOOOOOOo,..',;;',:ccc    //
//    cccccccc:;..,dOOOOOOOOOc'dOko.  ;ll:;;,. .;cloxxxkkkxxxxddool:. .:cloodddddddddolc:. .;lloddxxxxkkkkxxdol:. .';,;ll;. .:xxx,;kOOOOOOOOx;..,:cccccccccc    //
//    cccccccccc:,..ckOOOOOOOl'lkxo.  ;lloc;. .:clodxxxxxdoollllllll;. .:cloddddddddolc:'  ,lolllllloodxxxxxdoll:.  'cllc:. .:odl':OOOOOOOOo'.':cccccccccccc    //
//    cccccccccccc;..:kOOOOOOo'cdol.  ,lllc. .:lllc:;,''''..........,.  ':coodddddddol:'  .,'..........''',;:clllc' .:lcc;. .:llc'cOOOOOOOl..;cccccccccccccc    //
//    ccccccccccccc:'.;kOOOOOl':lcc.  ':c:. .,;'.....',;:::ccccc::,'..   ':loddddddolc,   ..',;:ccccc::;;,'.....',;. .:c:,  .;:c:':OOOOOOc..:ccccccccccccccc    //
//    ccccccccccccccc'.:kOOOkc'::;;'  .;:'   ..',;:cccccc:ccccccc:::,.   .;loddddddol:.   .':::ccccccccccccccc;,'...  .;;.  .;;;:';kOOOOl..:cccccccccccccccc    //
//    ccccccccccccccc:..lOOOx,';;;;'   .. .''.,;;;;:::::::;;;;,'...'.  ..';loddxdddol:,..  .'...',;;;;:::::::;;;;,'''. ..   .;;;;,'oOOOd..:ccccccccccccccccc    //
//    cccccccccccccccc;.,kOk:.,;,,'. ..,;..:olllllc:;,'';;,'.'',,;:,..';;;:loddxxdddl:;;;,..'::;,,''',;;,',,:cclllloc..,,'. .',;;;.;xOk:.,cccccccccccccccccc    //
//    ccccccccccccccccc'.oOl.';,....,clool,.;oddollcccc:::;;:clll:...;;;;:clodxxxdddlc::;;;'..:loolc:::::clcclloodo:.'collc;'...';'.:kx'.ccccccccccccccccccc    //
//    ccccccccccccccccc;.cl.....';clooodddoc,,:loolc::::clooolll,..;:::::cllddxxxxddolc:::::;..'coooddolc:ccllool:;,:odddoollc;,.....co.,ccccccccccccccccccc    //
//    ccccccccccccccccc:.'. .';clodddddddddddlc::ccclodddooooo:..,cccc::ccloddxxxxxdollc:::ccc;..;looddddddolllc:cldddddddddddolc;'. .'.;ccccccccccccccccccc    //
//    ccccccccccccccccc:. .':cldxxxxxdddxxxxddddodddddddooooc'.'clllc:cccllodxxxxxxddolccccccllc,.'cooodddddddddddxxxxxxdddxxxxdool:,. .:ccccccccccccccccccc    //
//    ccccccccccccccccc;..:llodxxkxxxdxxxxxxxxxxddddddooolc;.':lllccccclllodxxxxxxxxdoolllcllclllc'.,cloodddddxxxxxxxxxxxxdxxxxxxdollc..,ccccccccccccccccccc    //
//    ccccccccccccccccc' .cllodxkkkxxxxxxxxxxxxxxddddooll;'':lolcc:,;cllllodxxkkkkxxdolllll:;:clloo:'.;clooddddxxxxxxxxxxxxxxxkkxxdllc' .ccccccccccccccccccc    //
//    ccccccccccccccccc;. 'cloddxxxxxxxxxxxxxxxdddoooll:,,:loolc:,..;ooollodxxxkkxxxdollooo:..':loodoc,';clloooddxxxxxxxxxxxxxxxxdolc, .;ccccccccccccccccccc    //
//    ccccccccccccccccc;.  .;clodddxxxxxxxxxdddooollc:;,codddll:..'ldxdolllodxxxxxxddollodxxo,..:lodddoc;;:cllloodddxxxxxxxxxdddoll;.  .,:cccccccccccccccccc    //
//    cccccccccccccccc:. .'...;clllooooooooooollllcc::loddxxdlc'.'ldxxdollloddxxxxxdolllldxxdo,..codxxxdol::ccclllooooddoooooollc;...''..:cccccccccccccccccc    //
//    ccccccccccccccccc' .::'....,:ccllllllllcccccccloodxxxdol;..::;;::ccccloddxdddolccccc:;;;:'.,ldxxxxddolccccccccllllllccc:,'...';:' .:cccccccccccccccccc    //
//    ccccccccccccccccc:'..,::;,.....'',,,;;::::clloodddxxxdol;..........';::cclcccc:;,..........,lodxxxxddoollcc::::;;,,''.....';::;...:ccccccccccccccccccc    //
//    ccccccccccccccccccc:'.',;;;;;'.  ..'',;:cloooddddxxxxdoll:;;:::;;'....,,;;;;,,'...',;::::;;:cldxxxxxdddooolcc:,''..  .',;;;;;'.';:cccccccccccccccccccc    //
//    ccccccccccccccccccccccc:::::cc,.  .',:clooddddddxxxxxdollllllllllllc:,''''''''';cllllllllllcclodxxxxxddddddolc:;'.   ,c::::::ccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccc:. ....,:loodddddxxxxxxdoooodddddooodooolc::::cloooooooddddooollodxxxxxddddddol:;.... .:cccccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccccc;. .'..':looddddxxxxxxdddddddddddddddocodoooodolldddddddddddoooodxxxxxddddoolc,..''  ,ccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccc, .,,'.':loooddxxxxxxddddddxdxxddxdl',oddddddd;'cddddxxxdddddoodxxxxxdddoolc'.',,. .:ccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccc:. .,;;,,clooddxxxxxxdxxxdxxxxddlc:'.lxxxdxxxxo'.::lodxxxxddddddxxxxxdddolc,,;;;' .;cccccccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccccccc;. ';;::clooddxxxxxxxxxxxxo:;::ccd:;dxxxxxxxxx:;ol:::;;lxdxxxxxxxxxxddoollc::;,. 'ccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccc' .;::clloodddxxxxxxxxxxxd'.okxxxc:xkxxxkkkxkc:xxxkd'.oxxxxxxxxxxxdddooollc::. .:ccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccc:. ':cllloooddxxxxxxxxxxxx;.lkxkkdoxkxkkxkkkkdoxxxko.,xkxxxxxxxxxxdddoooolc:,..;cccccccccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccccccccc,..;clloooodddxxxxxkxxxxkc.:kkkkkkkkkkkkkkkkkxkkkkl.;xxxxxxxxxxxxdddoooolc:..,ccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccc'.'clloooodddxxxxxxxxkxkl.;kkkxdxkkkkkkxkkkxddkkkc.ckkkxxxxxxxxddddddooll,.'cccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccc:..,llooodddddxxxxxkxxkko.,dodlcdkkkkkkkkkkxcldod:.lkkkkkxxxxxxddddddool:..:cccccccccccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccccccccccc:..:looodddddxxxxxkkxkkd'.cldx:;dkkkkkkkkx::ddll'.okkkkkxxxxxxddddddooc..;ccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccc:..:ooodddddddxxxxxkkkx,'dkkkxc;:oxxxxdc;:dkkkk;'dkkkxxxxxxdddddddddl'.;cccccccccccccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccccccccccccc:..:ooodddddddxxxxxxxk;'dkkkkkdc,....':dkkkkkx,,xkxxxxxxxdddddddddo'.;ccccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccc:..:oooddddddxxxxxxxkc,okkkxo:;;:c:;:;:lxkkkx,;xkxxxxxddddddddddl'.;cccccccccccccccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccccccccccccccc:..;loodddddddxxxxxkl,lkxc,,:okkkkkkdc,,cdkd,ckxxxxxxxxdddddddc..:ccccccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccccc:,..coodddddddxxxxko;cl,'.ckkkkkkkkkkl'',cl;lkxxxxxxxxdddddo;.':cccccccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccccccc:..,loddddddddxxxx;.,oo'lOkkkkkkkkOo'cd;.,okxxxxxxdddddd:..;cccccccccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccccccccc;..;ldddddxxxxxo,;xko';oooddddooo:'ckx:'lxxxxxxxddddc'.,:ccccccccccccccccccccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccccccccccccccccccccc:,..;odddddxxxdodxko,lxxkkkkkkxxo,lkxxodxxxxxxxxdc'.,:ccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccccccccccccc,..;odxxxxxxxxxxo:okkkkkkkkkkx:lkxxxxxxxxxxdc'.,:ccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccccccccccccccccccccccccc:;..;ldxxxxxxxxocdkxkkkkxkkkxclxxxxxxxxxo:'.,:ccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccccccccccccccccc;..,cdxxxxxxdoxxxxxxxxxxxxddxxxxxxxl;.';cccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccccccccccccccccccc:'.':oxxxxxxxxxxxxxxxxxxxxxxxxdc,.';cccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccccccccccccccccccccc:;'';ldxxxxxxxxxxxxxxxxxxxl;'';:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc:,,,:odxxxxxxxxxxxxxoc;',:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc:,,:codxxdddddoc:;,;cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc:;:cc:::::::;:ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc;;;;;::cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//    cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MASKMODE is ERC1155Creator {
    constructor() ERC1155Creator("Plato's Melon", "MASKMODE") {}
}