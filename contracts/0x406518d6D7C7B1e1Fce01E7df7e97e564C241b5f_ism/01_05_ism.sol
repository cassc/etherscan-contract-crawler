// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Monkism
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNKKOOkddddxxxO000KXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNX0xdlccclodkkxxxkOkxdoddx0OkOKKKKKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNKOd:..  'x0O0XNXKKK00KOddxkOOOkkkOK0O0Oolx0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKxl:,.       'xOxoolloodddoollodddxkkxxdx0NXl .,ldkXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0xc'.       ....,;colc:clc::;:::lxoc:clokkoodk0OocodkkkOOO0KNMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMNXOo,.        ';loolll:;od'.,,..     ,l.  ..','.;xdokKK0000KK00x:;lkNMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMWXOl,.      ';cloddl:'   . .c;.;cc;;;;;;dk:',:cc:,'lo;:d0XXXXXK0OKOc::,;lONMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMNXk:.   .  .;ox00;....'''',;::oocldoooc;,,od'.,,,;:coxoodkKKXNNNXKXNX00O:...;xXMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMN0o,.    .;ldoc;''dl..;cc:cc:,'.;c. ........;c........:c:oOKXXXKKOOXNXXNWNOc''..,oKMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMNOl'     .,oxo;.   .:kxc;''.....  .:;.',;::cc:dxc::;,...;..;lxONWNKO0K00KKK0OKOo:.. .oXMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMNOd,   .. ,dkc. ...,cl::xl..'...:ccoxKXXNWXOOkxkOkkkOKNX00Odc::clOXK0KXXK0OOkxxOO0Ol;'..;kNMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMNd,'.....;o00c..':looc..';ol:cldxxdllokXWMWx. .  ,o' .,kNNNWNWN0xxkxO0kddkxdddolclddk0dc:ccl0WMMMMMMMMMMMMM    //
//    MMMMMMMMMMMWKc..';::lddllxOkdxdl,,'. ..lkdkWK;..ok:.oNWWk.    ';.   :0KXNNO:.'lkOOxc:looccooc:cc:cxOocxdlcoXMMMMMMMMMMMM    //
//    MMMMMMMMMWKd'':c;;dkxxc.,d0O00o,.. .:d0x;':0Wx..cxl'oNWW0'  ....  ..:0XXOc... 'x0K0olc::::ccclolcodxxxxxl,.;0MMMMMMMMMMM    //
//    MMMMMMMMW0c..:cloxxc',lox0OxkOko'.coc:kk:''cKWd,;c;,l0NMX; ',.:l. ...x0l.  ...l0Kk:.'odc;,,::::loddxddOkc.  'OWMMMMMMMMM    //
//    MMMMMMMWk;..;:;dkc::,':dxkkkoc,lxkKd. 'x0o'.lKKc.:oc..l0X: .. ..   .:l'.;xl. :00c.  'olcc;'.,;;:ldddodxOd,....kWMMMMMMMM    //
//    MMMMMMWk'....;x0dlldodd:;lxkdolc,.:OO:..c0O;.,Ox.'dX0o:lxl,;:cc:::ckO:;kNNl .kO;.  .:' .:l:,,,,',:ldolcckO:'..'kWMMMMMMM    //
//    MMMMMMO,.,;.'k0ocdk0KOc:clloxkdc,. .oKk;..lx, lKkddl::,... .cl,...'ll:dKNK;.ld'   ... 'ccc::,....';cooc;:dx;',':0WMMMMMM    //
//    MMMMMNo..;clkxldxdxklcdxl;ldc;,;::;::;oOx;.;cckk;....,;:::;cooc:;:cl,. 'odokx... ...,ldl,...,,...',;coc'.'od;;,.:OWMMMMM    //
//    MMMMMk'.,;l0O,...d0xc;,;oOOo;,'.;ddo:. 'xXKxc,,c:,coollc:;'''',;:clokxol;..:ddx: .:kkdl. ....',..'',,:lcc:ckd,,'.:KMMMMM    //
//    MMMMX:.;ccxxoooclxo:cc:ckk:;::;lx; .;c;.:kd,.;cd0KKK0OOOxxkkxxkOOkkxxkkxlcc:loxxldxl'.,;..'...',..',;:od:,'cx;.. .dWMMMM    //
//    MMMNo.'clkx,'',oOdcoo:,oxccc:cxxlo:. .okdcoxokOdlc:;,;::oOKKXk;,,,;;;;,,;ckOc';dOl.....;:....',cl:;;::coc;''c:... ;KMMMM    //
//    MMMK;.';oOc';,,oo...,ckOo::;lkkdolcldOd;:xO0KKK000000OOKNNWWWNKOO00O000KKKKKklldxl;,'..'oo::;;'.:c:clo:,c;'';c,....dWMMM    //
//    MMNx'...o0l;;.'xc. ..:x;.':lkOdoddoxkdccooc:ldocc::::l0WWNNWWNNNx;,,;;:ccccclxOd:cc,',;;ckl.   .'ll;ll,.;o:;:lo,,'.;KMMM    //
//    MNO:...,x0ooolOKxcc:lOk;...cx;':coxOkookkoolldxdxxxkkOKWWWWNNNWXOkkkOOOOO0000KKOl:dd:,.  ,d'  ...'c;,;'.'xd;:dOl,'..kWMM    //
//    MXo'...,ko...,Ox;cllkKdllcl0k;''.;ko;okxooooloolc:::lxONNNNNWNNOl:,,,',cccc::lokk,.c;     cl.  ...:c.',''oo,:dOd;;'.lXMM    //
//    MKo,',.;Oc...c0:...'xo..::d0c,::ck0c;x0dolloodxxdoox0NMMWWWWMMWWNX0kkkOOO0K0O0KKk; ,c. .. 'd; ..,,lxlc:::dxodxOk:''.'OMM    //
//    M0clOOclXklccOKolocoKd;llckk;...;kl'd0doollollllkNMMNKXXNNWWWNKKXNWWXl''',;'..''lc.,o:',,';xd;::cldkdll:;oxl:;lx:.'..kMM    //
//    M0ccxkcd0l;;'xk,,;:d0dclcd0d::ccd0o:k0l;::ccccclOWWk;..';oxl;,...;dXNOodddxddxxx0x',do,;,..oo.....,d:..'.:x,..,kc.. .xMM    //
//    Wk;,lo:xO,...lo. ..,ko.'':kl.',':Oo'dXxcccccllldKWd.   .'......   .oXWx::::::::;lo,'lc''...ld.    ,d, .'.:o. .;x; .  oWM    //
//    Wk,'lo:dKd::ckOccooxKkll:cOOcccccOk;l0xoooooddxONKc.',;cc;;,''''.. ,KNkdxxdddddddc,;oo;;;;:xx:;;;;lxc;cccxxcccod;,l;.oWM    //
//    Wk,'cl,cO:...lk;;lloOxllccOOccc;:x0l;xXkllllollxOd;';,,cocc:,,,:;'.'OXdlllcclccod' 'l;    .dc     co.';;cx:';;ol';:,.dWM    //
//    WO:':ood0d::cd0d:lccOOol:,lOl...':0k;l0Ooooooddkoc;.,ldolc'',,;od:..;:cddddddddxo. co'.   ;d.     c: ..':o'..,dc....'OMM    //
//    WKl;:lol00occckx'.'.lOc...;OOc:cc:lkl.lNNOkOkOO0kdc',,,'',..,'....  .'lxxxxxkOX0l;cko::. .l:     .l' .. :l.  ;d,.. .lNMM    //
//    MNx:co:'okodxdxKdclld0Oooold0o.  .;d0d:okl,;,,;:ldoloo;,;,..'...   .:l:;,,'''ck: .ll;clc:xx;.   .cc... .l:  .lc.   .kWMM    //
//    MMKocl:,l0kodxxKX0OOOOXOl;,;xkl::c:':kd:lOXX0OKX0O0Okdl:;cc:;'     ;d0XXXKO0K0d::c,.. ..lx:;:::;lo.    ,o.  'd,    ;KWMM    //
//    MMWk:,,,,dKkddlo0x:colk0c;lodk0l..'::lOd:cx0doxkO000koc..cxol,   .:lol:cc:lxOl,odlc;. .;d,.. .'d0o;;:,,l;   co.   .oNMMM    //
//    MMMXl.,cllOkoddcdOc'clxKOl:;..:kxlllokNW0:.'xXXXNNNNKxc.  .   .'lOKKKkd0X0o'.oOc..,ccclo;','. 'l,  .':kxc:,:d,    ;KWMMM    //
//    MMMMO,'lxxOKkdoodKXkxkocxd,';::cx0OKX0dlxKd:oxkKXXK0Oxdl:;;''''';,;:oxkocol:oOKOl.. 'xdccc:,.'c'...  ;o..'lx;    .kWMMMM    //
//    MMMMNl':dxdxOxdooxK0l;,.,kkll::okko:'...:KMWKdloO0KKOO0KKKK0000Oxxxccxc.;xXMK:,xNKo:c,..':cloo,.;;'.:o'  .cc.    :XMMMMM    //
//    MMMMMKc;:locxOc,:cokk;,lloOOoxxo;. .',..:OOxdxO0000xoxdoOkxkdolkl;dl;dkokNWXc.:0WWWNk;.  .'ll:cl:'.;o;...lo;'.  .xWMMMMM    //
//    MMMMMWx;,co::xkldxlo00dllcld00o;:cokXk,,lo:''c0X0xddddlcxoldo::kOlldKO'.'dXd''kWMMMMMWOl;co;..'clcod,...ox,;c' .oNMMMMMM    //
//    MMMMMMXl';lc,,x00Okdoxkxl:lxkKNXKNMMMNKXXd;:dkxl:lkOdlokN0olclONNo..dNd'';c;.;xKXNWMMMW0ddxc'..,:odooc;ox,.''..lNMMMMMMM    //
//    MMMMMMMNk:;ccclkNKxddllkOOOx0NKKXNMMMMMKl.'xOxkddXMKxoclKx;:;,c0Nl..lNNd'.......,;:dKKo'';:odc':dc;:ldOd'...  cXMMMMMMMM    //
//    MMMMMMMMWk:lxxccdKXkoxxxxOOO0K0Odl0WWM0:.'xKdcldKWNdoo:dKo,;,,:xKo..:KMNl...ckxoolclc'...',.,dOkc'';oOd;'''..oNMMMMMMMMM    //
//    MMMMMMMMMNkooddox0KK0Oxdddk00kdooddlo0k;,kWO;':OWWx,:c:kXo,,.;:cxo:;c0MMKc'''oNWXkdxc',;,'';oo;;ll:okl'.',',xNMMMMMMMMMM    //
//    MMMMMMMMMMW0lcokXWWWWK0Okdooxkxxxc',,,clkXM0:'lXM0c'.'oXNd:,.cdl::;,cKMMMXxoxkOx:;ccldoc:cood:'.'x0d,..  .;OWMMMMMMMMMMM    //
//    MMMMMMMMMMMMXd;:OWMWWNNKxollc:xXO:','',..;okOdoxko;'.cKMXd:::xN0:..'lXMMWN0koxd;,:c;,lOkddoloodkOxoc'.  .lXMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMW0lcxKXKKOkOxc,:xxccodo;'';:;,;oxxxddodOXWMNkldx0NWKodkOO0xc:;'.,do:c;:oddk0xodkKXklcl:. .:0WMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMNOccloodooxxd0d'...,lddooc;;dkodkl;';;;kkcxKkoolckx,'..:l. ..  'kkolcllox00k0XKOxl:,',cOWMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMNkc:cclodddxxo:,;;;;codddk0dlkd:;:oc'dc.:kl,.  cd... 'xc..';::lOl...,oOKX00XKOdc;;oXWMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMNOdc;,;cccoxkkdc:,;cc;l0Okkkdlc:llcxc.ck:... ;o..';:k0oll:'  'l;.:dkkxOOOOxc,;o0WMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMW0o,...';,:dkkxdolccxkoddoooooolk0dlk0xlllcx0ocloddOx,'''..,dOdolcclxOko:;oKWMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMXkc'....',,codocdkccccc::;,'.:k;.lOo:clcox;.',;,lOdlodxxdl,..;clolldOKWMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMWXkl;.......;xOkdddollc:;;'cx;.ckocloldOdlolodxOxoc::'...'',,:oxKWMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0ko;..;0MMWNXKK00K00OkO0kkOOkkkxxO0OkOOxol:;.. .....,:okKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0xxk0KXNWMMMWWWWWWNNXXXNNXNKOKNXNWNOc:;'....,:okKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXKKKKKKKKKXXXXNNNNNNXXKKK00OkxoccccoxOKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXK0Okkxxxxxxdddddxxdddxk0KNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ism is ERC1155Creator {
    constructor() ERC1155Creator("Monkism", "ism") {}
}