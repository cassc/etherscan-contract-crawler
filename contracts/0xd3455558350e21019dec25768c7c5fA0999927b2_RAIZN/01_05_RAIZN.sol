// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: RainZen
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                      //
//                                                                                                                      //
//    x:;;;;cc:c:;:;;:;:cc:;::odc:,';::llllol:;;;:::;,:;,:cc:cc:;:c;:::::cc;'',;::::;;;:cllolc::,;co:':c:',,...:o:;x    //
//    o;;;'.',;;,,..''';;,'.',::'.....';:lll:,'.',;,,,,'',;:::c:;,,;;:,',;;,..':c:;;;;;',;;;,,''',,,.',''.....,;;,.:    //
//    d:,',.,;;,.;'':,,'.,..,,;;,..','.,::::;''''...................',,,,',;,.'::,;::c:;;;'..'';,..,,;,,.  .,,;,.. ;    //
//    d:;.';::::,;:clc:',;,,;;;;,',:c;'.....,,'....'.',;:,;lccc:;'..  ..,,;:'.,;,,,,;,;:;'..',:;..';;'....';:'.. .'d    //
//    xcc:;;:::::::lc;,,,:llc:,,'';;,'...........'cl,,:,..'ckKXNXKOo'.........,::;..',;;',;',;;,,'';;...;:'.'. .,:ck    //
//    xlc,....:cllcl:.  .,cc:;:::;,;;;,...;;......cc'..   ..,ckNNXKOkdxkd,..  ..''';::;,..,''..''..';:;,';,...,coolx    //
//    xc:,.. .,cccc:,. ..;cc::::cc;'.,'',',;.  ...;:'.    ....l0kkxkKK0Okxdlc:'  ...''',:::'''.;:;;,,;;;'...,:ccloox    //
//    xccc;....:c;:;...';:ccc::;;::'.,'.',.    .'';c'     .'..,l;,dK0xloO0Oxdol:;;'.  ..:l:,''..';c;,..:;.,:ccccllcd    //
//    kclllc'...''''...',;::;,'...':c:,,''.    ....;'    .... .;:o0kc,:xOd:',lO0Okd;.   .....',,;;:,'..:'.,:;,,;;:;l    //
//    kcloc,.'',;,;:;,'...,,.......:ol;,;;'.   .',,:;.  ......';o0k:,cxOl..;d0KOo:looll:,.   .::cc:''..cc;,....';ccd    //
//    d',;'.';,,;',;',;....''.';;;:cll;',,;'    ;l:od:......',,cOx:;ckkc..:x00xoc,cO00Oxl'.   ....,''..;,...'..;;;:d    //
//    c....';,,,:::;,;;,''..:cll::c:::lc;,;;...':ccloc;'...;oxcckd,;xO:..cx0Ol,cloOK0Odc::,...     .'...';;;;;'....c    //
//    d::..;:;;:ldxdc,'',;'.;lccc:::;:lc'...;:codooxxdl;,;;lxdclOk;:xk;.ck0xl;;loOKOdc,;cl:;::,'''...'',';:;;:;....c    //
//    klc' .::;:cllc:,',;'..,,',;;;;;:;..':loclxdllddo:,:lllc;:x0d;lOOc,oOkol:;x00dc;;,;coolllc:;;;'. .'.,:;;c;,,..l    //
//    kcl:..;;;;,,,,,',;;..'...  ...'..,ldxxlcoool:c:,,''clcccx0x:cx0x,,d0k:,lOKOo;;;;coooc,,;;,:dxxc. .;;;:;;;,,''l    //
//    k:;'...,:,,;,,,,'...:c;,'...  .'ldoddl:odccc;;,',,.;c:okOkc:d0x:;oOKkl:oK0d:;:ldxdl:,,,;:loxdoxl. .';::;.',,'l    //
//    d.. .;:,,,'.......':c:cccc;. .:oxlcc:clol::::::,',;c::xKkc:dOk:,oO00dccxK0o:cdkxo:;;;:clddo:.,dkc. .',;;.....c    //
//    c  .,clcc;..';;;'..';:c::;...:oolc:,;:clc::cc:c:,;,''ckOo;oOx;,oO00xc:oOK0d:lxxo:;,,coddoc::,;dkxl'. .;;'''..c    //
//    c .,::ccc,..:cll;.  .';:;..,llc;,...',,,,'';,:l,';;'':dxl:dOc'ck00dc;cOKKOo:lxxl,,;coolc:,,;cokkkkdc' ..'::':x    //
//    l.,::::c:...;lcll:..  .,..;ol:,..... ..,,...'lo;;c;;cccc:;ox;;x00ocolkKK0d::oxdl,,cooo:,'':oxkkkkxxxo;. .',;;d    //
//    dccc:::c;. .;cclc:;'.....,:cl;..   .'::;,;;',oo,;c;;;;;,,,lo,:O0kc;lkKKKx:,lxxdc,,codl'..:dkkocoxxxxxdc.  ..,o    //
//    Odl:;,:c;...;c::;,;lc;. ';;cc,.'',:clccc:c:,,ll'.;;;;;::;':c;lOOl,,oKKKkc,:dxdoc,;lodc'.:dkko'.'lxxxxxo;'.  .o    //
//    x:::::loc;::lo::::::,. .,,,;cccc:;::::ll,:c;';c,..,;cl:,'';c:lOkl:oOKKOc;:dxddl;,:ood:',oxkkl;;,cxxxxd:'','. ;    //
//    o,;,,;:;,;cclc,::::,. ..,',cc:c:;;;::;''';c:'.:c,',;ox:''';:,:kk:,o0K0l,;oxxdl;;:lodoc:ldkkxc;:cdxxxxo,..;ol;l    //
//    o,''',,,,;;:;;;;;,....,;'.,::looolloddo;';cc;'':c'.'okl,,',;,:Okc:xK0d:;lxxdl;;;coddo:coxkkd:,;oxxxxxc'.,lxxxO    //
//    o;;;'.''';;,,,''.. .,clc,,cccolllc;:;:dxc;coc;,,:;.,lkd:,',;,cOx::kKk:;okxxo:;:coodo:':dkkkd:,:dxxxxo;,,;oxxxO    //
//    o;;;'.'..,;:;'... .;;';;;okkdloO0Oxdl:;lxc:ol:;,''..;ool;',:cd0o:lO0o;cxkxo:,,:loddl;;lxkkkl,,cxxxxd:,;,:dxxxO    //
//    o;::,''..,cc,... .,,.;:;:loxkxkKKOkOOo,,lo:odlc:,',';;;c;';clkOl;o0kc:dkxd:,,:loodo:,:dkkkxc,:oxxxxl,'',lxxxxO    //
//    d:c;,;,'....... .';,:clloolllodkkkdlxOl':oclxdl:c;;c;.':;,ldx0xcckKx;cxkxl;;:loodo:.,okkkko;,lxxxxd:',;oddxxxO    //
//    d::;'.',,;'.......':c:cclollllllcloox0k:,llcxkollc;;'.'cclk000o;d00o;lkxdc,,cooddl,':dkkkxc,;oxxxxl,':ddoodxxO    //
//    dc::;,,,,;,...   ..,cccllccc:cllcclldOKklxo:dOoc;'... .';lx0K0l;kKOc;okxo:,,coodo;.'lkkkko;;cxxxxd:',lxo:cdxxO    //
//    xlccc:cc;;'..     ..':clllllc:c:::cco0NNNX0xkkc'....',,;,..,oOkkKKd;:dxdc;;;loddl,'cxkkkxc;cdxxxdc,,:ddl;ldloO    //
//    d:,,:::c:,...      .':cclcclccc:;:locdOxOXXOl'. ';:;,c:;:c,..'o0KOl,cxxdc;:loodl;.,okkkko,,lxxxdc'';lxo:cdlcoO    //
//    o,'''::;:,...   ...  .;::c:;;;:cc:lc':o;co:. ...''','',,;;;:,..cOx;,lxdl::coodd:..;dkkkx:':dxxdc,,,cdo::ooccdO    //
//    l.'',::::'...   'c'   .',;::;,::ccc;.',......,,'...',,,,'.,;;. .:xlcdxdc,;loodo:,;cxkkko,,lxxdc,',cdd:;ldl:lxO    //
//    d::ccc:::;'...  ';.     ..',,,;,,,,.......,,'..''''...,,'';;;,. .:dxxdl:;coodd:'.'lkkkxc':dxd:'',:oo::ldoloook    //
//    xl:;;;,',,,....            .......;;',:,..','. .';,...,,,..,;'''..:dxo:;:loddl:;;cdkkko:;oxd:'';lol;:odolodocx    //
//    dclc;;c:,,,.....            ...,,',::,..''';;,,,,::,';cc;..,;;,;'..:oc,;loodo;..,okkkx:,lxd:''cdo:;cdxolodo:ck    //
//    c,c;.',';c:'.....          ...:ol,.';;. ..;c;;;'...::;''',:c'..,,. .;lloooooc;;:okkkxo;:dd:.'cdo::ldoolodo;,lk    //
//    xcc:;;;:;'';:,..............';;,',,.,;'';,'.':c:'';ll;','.,,,,,;;,. .;loooo:'':dkkkko::od:''cdl:cddoc:odd:.;dO    //
//    Oc,;::;:;';:;','','......'';llc'.''..';:,',,,;,,..,;,,::;;'.,c;...'. .,lodl,':dkkkxl;;od;.,ldc:lddlc:coxo;,lxO    //
//    o:;cc'',,;;,,::;';c;',;,,:::ldo:,,'..,;'';:l;.',..,;.,xko;'..''...''.  'cdo:cdkkkd:,:od:':odc;lddlcllldxl,:dxO    //
//    c',',,;'.,cc,,;,''::.,c,,cc,,cc;'';,,:'..,:xd.':. ,;.:kxc'....;:,,,;'.. .;ldxxkkkocodxdclddc:ldollooldxdc:ldxO    //
//    d;,,'':;,;cc,,;;,';:';c:cl;:dl,,,',:l:...''':,.,' ,,.:;.... ..,,...;:,.  .'lxkkkkkkkxxxxxxoloxdooxddddxdoodxxO    //
//    0xddoloddolddoddddddldxxkkdxOkdddodxdolcccoccolol:oolollll:::cooc:lol::::::dO00000000000O0OOOOOOOOO0OOOOOOOO0K    //
//                                                                                                                      //
//                                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract RAIZN is ERC721Creator {
    constructor() ERC721Creator("RainZen", "RAIZN") {}
}