// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Raices
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    kkxxxxkkkOOO0000OOkxxdoodxxxxxddlo00xddoooooddddddddooooddddddkKK00OOOOO00OkkkOO0000KK00OOOOOOOOO0Kk    //
//    xxxkkOOOOO0O0OkkkkkxxxdoookKKXXXK00OOOOkkkkkkxxxkkkkxdooolccc:lOXXXNXKKKKK0OxxxxxxdddddddddddddxxkOx    //
//    dddddxxxxkkkkkkO00KKXXXXK0000KKOdolcldddxxxxkkkkkkkkxxxdol:;,'cOKKKXK0O0KKK00000000KKXXXXXXXXXXXNXXk    //
//    00OkkkxxxxxxxxddxxddddooodxOkoc::loxk000KK0KKK0000000KKKK0OkxoccldOKXXXX0xxdddddddxkkkkkkkkkkOOO00KO    //
//    kkOOOOOOOOkkOOkkOOOOOkxddl:;;:oxO0000000000000000000K000K000KK0ko:;dKXXX0kkO000K0KKKKKKKKKKKKKKKKKKO    //
//    lloooooooooooollllcokOOxl;;cxO000000000000000000000000000000K0KKK0kollx0KK0kdddddxddxxxdddddddddddxx    //
//    xxkkOOOOOOOkkkkkOOOkOkl,,lxO000O00000K0OO0KKK0000KK0kxxk0KK0000000K0xl:d0KK0OO00O0000OOOOOOkkkkkkxkx    //
//    lolollooooooooooooodd:,cxO0O00O0000Od:,''';dKK0KOoc:'..';o0K0000KKKKK0xoc;lOXKKK0000OOOOOkkkOOOOOOOk    //
//    OOOOOOkkkkkkOkkkxkxc,;dOOOO000O0000o..',,,..;kXk,..',,,,'.;kK0000KKKKKKOd:.,xK0kxxddddddxxxxkOOOOkOO    //
//    lllllllcccllllcclc,':xOOOOOO000000l..,,,,,;,.;k:.',,'',',,.;OK00000KKKKK0d:''o00OOOkkkkxkkOOOOkkkxxk    //
//    OOOOOOkkkkkkkkOOkl,:xO00OO00000Od;.',,,;;;,,,....,,,,,,,,,,.oKK000KKKKK0K0d:'.cdddddxxxxkO00000O0OOO    //
//    ollooollllllllloc':xOOO00O00O0x;..,,,,;:;;,','..,,,,;;,,,;,.lXK0000KKKKKKK0d:''xNXNXXXXXXXXXXXXXXXXK    //
//    OOOOOOkkkkkkkkOd,;dOOO000OO000:.',,,,,,,,,,',,'',,,,,,,,;,.,OXK00KKKKKKKKKK0d:.;kkdddddxxkkkkkkkkkxk    //
//    oooolllllllllll;'lkOO00000OO00x:,'...',,,,,,,,;;'''',,,,'...:xXX0KKKKKKKKKKKOo,.l000KKKKXXXXXKXXKKK0    //
//    OOOOOOOOOOOOOOd,,dOOOOOOOO000000Okdc'..,:;,'.,,,:cc,.,,,'','..xXK0KKKKKKKKKK0x:.:0KOkxddddddddxxxxxO    //
//    lllloooollllll:':kOOOOOOO000K0kdl;,'..',::::,.;locc'.;;;;;;:. lXK0KKKKKKKKKKKxc';OK0OOOO000000000000    //
//    kOkkkkkkkxxxdd:'lkOOOOOO0KOo:,'...';::;;,'.',;c;....,:cccc::..oX00KK0KKK0KKKKkl';OK0OkkkxxxxxxkkkkkO    //
//    llooolllllcccc;,lOOOOOOO0Xo...',,,,clc;;;;,;l::l:;;::cclc:::..xX00K00KK000KKKkc':kxdooooddddddddxxxk    //
//    00000OOOOOOOkko;oOOOOOOO0KOo;,'..',;;;;;;'.,;..;,';;cllc:::;.'OX0KKKKKKKKKKKKx:'lKXXXXXXXXXXXXXKXXXK    //
//    olooooooooooll:,lOOOOO0000O00Okd;..,,,,'...'..,'..,;:cc:;;:,..kX0KKKKKKKKKKK0o,,dOkkkkkOOOOOOOOO0000    //
//    ddolllclllllll:,:kOOOOO00000000KKx,.,'.....,,,,'....,;;;;;;..l0K00KKKKKKKKKKkc':kkooooooooooddoodddx    //
//    dddoooollllloooc;oOOOOOOOOO000000KO:,;'...,::;;,. .',..','..oKK00000000KKKK0o,'dKKKKKKKKKKKKKKKKXXK0    //
//    ooolllllllllooll;;xOOOOOOO0000000KXKKx:,..,;;;;,'. ,xxl;,,:kK00000KK000KKK0d:'c0KKKXXXXXXXXXXXXXXXKK    //
//    kxxxddddxddxxxxdl,;xOOOOOOkkOO0KKK0K0ccl..;,,,,,,'..,OXKKKKK000000KKK0KKK0x:':kOdddddddddddddddddddk    //
//    dooollllooooooolll;;dOOOOkd:;:cdO000k:ok;....',;;,'..dK00K00K000000K0OxO0d:':kKkdddddxxxkkOOO000K000    //
//    xxddooooooooddddddl,'lkOOkkl''',;lOKO:c0KkxxkkO00OkOOK0000000K0000Odl;,ld;'cOKKKKXXXKKXKKKKKKKKXXXKK    //
//    doooooooooooooooooolc,;okOOx;,:lc';x0l,dK00K00000000000000000K0Odc;''.,o:'lOOxxxxdddddddddddddddddod    //
//    xdddooolllllloooooooo:'.;okOl;::oc',dk:;xK000000000000000000Kkc;;,'''.;xod0KOdooddxxxxxxxxxxxxxxxxxk    //
//    ddddooodddddddddoooddddl,.,oo::;;l:',okc:xKK0000K000000000K0d;;:,,;,.'l000OO0OOOkkkkkkkkkkkkkkkOOKKK    //
//    ddddddoooooooooollllloool;..',,;,',,',lOd:oOK000000000000K0o;c:..::..:k0OxooooooooodddddxxxxxxxkO0KK    //
//    kxdddoooooooooooooloolllllllcll:'....''ckkc:d0K0000KK0KKK0o;c;.'c:..:k00000KKKKKKKKKKKKK0000000000KK    //
//    OOOOOOkkOOkkkxddoooooooooolllllodl;'..'';oxd::xKK00Okxddkx;',,;c:..lOOdllllllllllccllllllllloooooooo    //
//    lcccccccccc::::ccccccccccccccllokOkdc;'...,;;''ck0Odc::lxl'';;;,,:x0KOkxkkkkkkkkkkkOOOO0000KKKK000K0    //
//    OxdoooollloddxxxkkOOdlccloxOOOOkkOOOOkxolc:::,..,okkkkk0k:':;,:dk000000000Okxxdoddx0KKKKKKKKKKKKKXXX    //
//    OkkkOOkkkkkkxxxxxkOo'.'''';lxkOOOOOOOOOOOxoool:,'',ckKKKx;:c:d0KKK000Oxoc:;;,,'''',cxkdolllllllooooo    //
//    xdolllllllccccccllxl..''..',;:ldkkOOOOOOO00OOOOko;,',oKKo':d0K00KKOxc,'',,,,,''''''';dOOOOOO0OOOOOOO    //
//    lcccccllooooodddxxOk:..;;..''..,;ccccllooddooodxxxdl;,lOl;xKKK00ko;',,,,,,:cllodxxxocx00KKKKKKKKKKKK    //
//    doooollllllccccccclldl:;,'''....,,....',:lloodddl::::;';;l0KKKOo;,;;;;:ldkOkdodooooooooooooodddddddd    //
//    l:cccc:ccclclllllllodOOxoc;,,'',;::clodxxkkOOO000o:,.....:kK0d:,',:ldkOkkkxdlccclclllooooddddddddddd    //
//    Okkkkkxkxxxddddooollcccccccccccccccccc:::::::lxO0xc;.....'coc,',cdO00OdccccloooddddddxxxxxxkkkkkkkOO    //
//    dooooodddoollc::;;;,''''''.......'''....'''''ck00kxc.....'''';lk0K0Oxoc::;;;::::c::::::::::::::;::;:    //
//    oc::ccc::::;;;;;,......';'....'''',,;;::cllodkOOOOkc.;;..'''ckKKKK0x:,;:cclldxdl,.,ldll::::;;;;;;;;;    //
//    l;;:ccc:::::ccol,......,llclloddddddxdddddddoooodxd:.;;',',okOKKKKKK00KKKK0KKK0c...;llc:::cccccccccc    //
//    xoddoddodxxxxxx;...':oxkOOkdolcccccccccccclllclloddc..';;,dOkk0OOOOOkkkxkkO0KKKx;..'cl::;;:ldOKKKKK0    //
//    Oxdoollcc::cdkxc',cddooolcclccloddxxkkkkkkkkkkkkkkkc...,;lO000000000OOOkxxxxkOO0kl,.........':ddllll    //
//    oc::ccccclodxxoc,',,,:oxkkkxxxxxxxkkxxxxkkkkkkkkkxo;...':k0O000000KK00KKK000000Oko;.;oxdoc:;;:dOOOkk    //
//    0Okxo:lk0ko:,....;cll;;okOkxxxxxxxxxxxxxxkkkxxkkko;,....lOOOOOOO00000KK0OOOO0K0kdc:oooodOkollooooodd    //
//    kl::clol:......,okOO0d':kOkxxxxxxxxxxxxxxkkkkkkkx;.'. .'oOOOOOOOO0000kl;',;;:lc,.:k000xollldxdoollll    //
//    kdxxoc:c:...';lkOOOOx;.cxxxxxxxxxkkkkkkkOOxddool;.... ..cddxkOOOOOO00kl,.'';cloldO00OO00Oxoldk0OO00O    //
//    KOdlldxkd'.cx0Okxdc,',cdxxkkkxolloooool:::,'''....    ...,::coxOOOOOO00kxxkOK0000000O000000Odlok00OO    //
//    0kkOkxxxxloOOkxko;';lxkkkxo:::cllcccoxxo:,,'....'','';::,,;;coxkkOOkkO000000000O0000OO000O000OxookOO    //
//    OkOOOkxxkOkxxxkkxddkOOxl;,;clolccclodl:,..'',;:;:od;;kOxxxl'.',:loddoddooooodxkk0OOOOOOO0OO0O0OOxodO    //
//    OkkOOkkxxxxxxxxkkkxolcc:coddoodxxdc:::;'';lodd,.lkxc,okxkOl:odo;.':,,cc;'';cllllllokOOOOOOOOdlxO0Oxx    //
//    OkkOOOkkxxkOOkdolc:codlccldkxkxl;;:cod:'cdo;co;'ckOxc,dkxkc:xxkkl;:ldOkl;cc:lk0OkollldkkOOOOOdccdOOO    //
//    OkkOOOOOOOkd:;;cdxkko;:okkkkkd:;ldddxdc,;xl'cxo,;xxxd;cOxkx::xkxkxc,lkdddlod:;dkkOOkdoooloxdoxOd:lkO    //
//    OkkOOOOOkd:'cdOOOkd:;okOkkkOx:;dddxxxxd:,ox:,ox;;dxxo,cOkxkx:okllxkl,dx:lx::k::kkkkkOOOOOOOkdccxkldO    //
//    0OkOOkkkOdlx00OOxl;lkOOkOOOd:.:xxkkkkxd;'okxc,lo;:oxl,oOxxxxookl';dx;ckdldc,xo;dkxkkkkkkkkkkOOo:oOOk    //
//    00O00OOOOkO0OOOd:cx0OOO00xc;ll;oOkkxdo:,,;oxxl,ldc:oolxOx::oookxc'cxc:dxxkc;dkccxxkkkkkkkkkOOOOxcoOO    //
//    000000OOO00OOOxoxO00000xc:cxkkc:dkkdc,.cdl;;ldl;okxxxxxl;:oxloxxc,cxc,ldxxl,:xxclxkxkkkkkOOOOOOOOkkx    //
//    0000000000000000KKKK0kocokOOOOd;lOo;;':xxxdlcdxddxxxko::dkxddddxl,;dolldxxxo;:do;;oxxkkkkdxkOOOxlddc    //
//    00KKK0KKK00K000KKK000OO000000Oo;lkoododxxxxxkxxxxxxxl;lkxdddddooo:':ddooddxxxloxdc;:dkxl:ldo:ckl.',.    //
//    000KXXKKKKKKKKKK0K0000K0000000dcxOkkkkkxxxxxxxxxxkkdcdkxdddddooooo:coooooddxxxxddddodxo;,::'..,;,,;;    //
//    KK0KXXXKKKKKKKKK00000K00OO0000OkkOOOkkkkxxxxxkkxxxxxkkxxdddooooollololllcloooooodoooooooc:,.,',clclo    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract RCS is ERC1155Creator {
    constructor() ERC1155Creator() {}
}