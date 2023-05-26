// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Strawberry BEAST
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                            //
//                                                                                                                                                                                            //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK00000OOOOOO0KKKKKKKKKKKKKKKKKKx;..';'...'oKKKKKKKKKKKKKKKKKKK0l....:OKKK0kl,.............',:ldk0K    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0koc:cdOKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0Odlc:;;;,,;:lloodk0KKKKKKKKKKKKK0x;..,c:....'dKKKKKKKKKKKKKKKKKKKOc....l0KK0d,.....,:lodddxxxkOOkkkxd    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0xoc;...cxO0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKOdc,..';::;...',::,.'cxO0KKKKKKKKK0x;..:dc.....cO0OOxdoolodk0KKKKKKKk;...'dKKKk;....,dOKKKKKK0kdoc;'....    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKOo;.......:x0KKKKKKKKKKKKKKKKKKKKKKKKKKKKK0kl,...:dkdc,...',;;'.....':oOKKKKKKKx;.'lxc.....':c;,'.......';clodxxo:....:OKKOc....ckKKKK0kdl;'........'    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKK0Odcldddo;...'lOKKKKKKKKKKKKKKKKKKKKKKKKKKK0d,...,dOd;....,oxkkxoc,......'cx0KKKOc':xx:...........'''.................,lk0KOl....lOKK0ko:'.........'cxO    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKOo::lldOKKKkc....:k0KKKKKKKKKKKKKKKKKKKKKKKK0o',;.'x0o'.....,;,,'.............:odxxl:c:'....''..........',,'........,;cdk0K0x:....lOK0xc'...........:x0KK    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKK0l.'d0OO0KKKK0x;...;x0KKKKKKKKKKKKKKKKKKKKKKKx,.;,.cko'...............,,;,.................;lc.......':okOOOxoc:;,,,,,';lxOkc'....lO0xc'...........:x0KKKK    //
//    KKKKKKKKKKKKKKKKKKKK0kdooxkc..;dxxdollllxkdodxOKKKKKKKKKKKKKKKKKKKKKKK0o....;xx,.............,ldo::::;'............,coc'.....'ckOkdolccc:;'...'.....,'.....'::,...........':x0KKKKK0    //
//    KKKKKKKKKKKKKKKKKKKKk;.,,';c:'..';:c:,..'xKKKKKKKKKKKKKKKKKKKKKKKKKKK0x;...;xx;..''.........ckx:.,colc'.';ccc::;'''''''....'ckOd:,coolc;'..............................';lk0KKKKK0xc    //
//    KKKKKKKKKKKK0OxdodOK0l.,ll'.,coxxkkdl,..cOKKKKKKKKKKKKKKKKKKKKKKKK0Oxc'..'lxd;..''........,lkd,'coc,..,lk0KK0000Okkkkxc..'ck0Oc';xOxc,....'cdddolc,.................':dk0KKKKK0ko:..    //
//    KKKKKKKKKKKOl;:loxOKKx;.':;,..;dOd;..'cx0KKKKKKKKKKKKKK00Okxxxxxdl:;'.':lll;.'::,........,lo:..lo;...:x0KOdc;,,:clloo:..,d0KOc.:k0d::;...'o0KKKKKK0xc'................;cddoll:,....:    //
//    KKKKKKKKKK0d,'lO0kooxOo'.'oOxc''cxkxxO0KKKKKKKKKK00kdlc:;;,;:clolcclccc:,..,cllc,.........'...ld;...;oxdc,.............,x0K0l.;k0d:;,...,d0KKKKKKKOl,............,'.............,:d0    //
//    KKKKKKKKKKKOo'.,:;:ok0Ol..;k00kdx0KKKKKKKKKKKK0ko:;;;,''',;;:c:;;,,,,,;:ccloodxo'...........;dx:...:k0Ol....,'.......'lkKK0o''oOo,.....,x0KKKKKK0o,.'coo;......'dOkxdocc:::ccloxO0KK    //
//    KKOxdoddk0KK0x;..:kKKKKOl'.;kKKKKKKKKKKKKKKK0xl,,:llddxxkkkkxdolccccccccc:::lol,........':ldOOc...,xKOl...'lxdl;.....;clll:',lo;......;x0KKKKKKOc..,xK0o'......o0KKKKKKKKKKKKKKKKKKK    //
//    Kkc:odc',okxkOkl,.,oxdoxOkdxOKKKKKKKKKKKKKKkl,,cddok0Odooddoollc:;,..................':lxOOOd:...;d0Ol...'cc'...............''......'lkKKKKKKKOc..,x0kl'......lOKKKKKKKKKKKKKKKKKKKK    //
//    Kx;:kOl..,:cc:;:l:'..,cx0KKKKOddodOKKKKKK0x;.'lkooOOl,.,;:,........,,'...............',,;,,'..':okOx:...;lc..,;:;'................':x0KKKKKK0k:..,cl:'......;d0KKKKKKKKKKKKKKKKKKKKK    //
//    KOc.,;',oO000k:.,ddloxO0KKKKk:;l;.l000KK0d;..cklcdl,..';'.....',,;:lc,.....,;:cc::;;;;'...',:clllc;'.,,;;,.'::,...':lllcc:;,'...:dO0KKKKKKKOl'.........',:lx0KKKKKKKKKKKKKKKKKKKKKKK    //
//    KKk:.'lOKKKK0d;.cOKKKOl:d0KKd'':,'clcd0Ol,,.'do,,'';,:c,.....;;:lccc'...'lk0OOkxddooc;'..',;;;;;;:clc,....;:'...,okkdlllllc:;....;ldxkO00kl,.......;ldxkO0KKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    KKKk;.;x0Oko:,;oOKKKK0d;':oOOl;,,;:cdO0l,:;.,o;..,l::o:.....:;;dllo,...:k0kolodddooolllloxxxxxxxkxdc....;l:....,ll:::cloooolc:,....,,',,;'........:OKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    KKKKk:.';;;;cdO0O00KKK0d;'',:oxkO00KKKk,;l'.,c'..cl,lo:'...;:'odld:...:OOl;:oolc:;;,,,;:lllloll:,....'cxkl.....',;;;,'............',,'...........'dKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    KKKKKOl,:dk0KKKOdoOKKKx,'od,.;lx0KKKKKo':l..,c'..ll,ddc;...:c;dooo'..'dk:'::'...........',;;:c:,...'lk0Kd'....',,,.................','...........cOKKKKKKKKKKKKK0Okxxdxk0KKKKKKKKKKK    //
//    KKKKKK000KKKKK0K000OOOk:,::;lOKKKKKKK0l'cc..,o;..ll;xxlc'..,:;ddoc...,dc........................,:lkKK0x;.....,'.....''...'''...................:kKKKKKKKKKKKKKKOoccc::oOKKKKKKKKKKK    //
//    KKKKKKKKKKKkooxO0Kkdc;lxkkkO0KKKKKKKKKx,;:..'dl..lxokOooc'.:lcxxdl'..,:........................'cdxxdo:'.................'','.................;oOKKKKKKKKKKKKKKK0xcccc:lkKKKKKKKKKKK    //
//    KKKKKKKKKKO:':oool:oxolk0KKKKKKKKKKKKK0l....'dkl;;odlc;,;,',:coodkl,..................''.............................'coxOOOOkdlc;,,,,,,;:cldk0KKKKKKKKKKKKKKKKKKkl:cc:cx0KKKKKKKKKK    //
//    KKKKKK0OO00xoodxkl.;OKKKKKKKKKKKKKKKKKKO:...'xKOl'';:codddl:,;,'';coc..............,loddoc::,................';....'ck0KKKKKKKKKK0000OO000KKKKKKKKKKKKKKKKKKKKKKK0dc:::coOKKKKKKKKKK    //
//    0kOOxo::c:cox0KK0xox0KKKKKKKKKKKK00kdoooc,,;okd;,cddlcc:::;;;:c:;,.':,............,oooooolllc:'.............,oc...;x0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKklc:c:lOKKKKKKKKKK    //
//    0OOkl'.'lxdoxOKKKKKKKKKKKKKKKK0xooo,.,lddl',o:':do;...........';cll;..............,:cloddddool:,..........;lxl'..'dKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKOoc:::lkKKKKKKKKKK    //
//    K0xccc:,:xKKKKKKKKKKKKKKKKKK0x:'.,'..:OKKk,..,okl.......''.......:ld:.''..........;cllcc::;;;;;,.....;cloxOx:....cOKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0xc:c:lkKKKKKKKKKK    //
//    KKOl,,lxO0KKKKKKKKKKKKKKKKK0o,:dc....:OKKk;.'d0o.....'ldddl;......,;:'',....''....'..................;cclc;'...'lOKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKOoc::cx0KKKKKKKKK    //
//    KKK0kookKKKKKKKKKKKKKKKKKKKx;cOKk,...cOKKO:.:Ok;.....:l;'','..........,oxxxxo:'.........:loooc;..............,lx0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0xccccd0KKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKK0c;k0kc....ckxdl,.c0x'......................,dOko;....,ldxo;..;dO0KK0kl'....,:ccloxOKKKKKOoc::oOKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKkl:cclOKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKO:cOx,.....;:.....cOd'........................''....':dkO0KOl'.,cxKKOd;....;kKKKKKKKKKKKKk,...,xKKKKKKKKKKKKKKKKKKKKKKKKK0000KKKKKKKOxdx0K0dc::lkKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKk;:d:';'..........,kk;......................';::lodxdlc:,ckK0c.':loc,.....'d0KKKKKKKKKKKKO:...'dKKKKKKKKKKKKKKKK0xdoox0K0d:;lOKKKK0x;..,xK0xlllx0KKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKk,.;ldl,...''......ckd'....................,x0KKKKKK000x,.l0O;.',,,;::,...l0K000OOO00KKKK0koooxOKKKKkoc:cd0KKKKKx,...:OKKo'.'d0KKOl'..,d0KK00OkkOO0KKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKO:..'......;dol,;do:lkx:'..........'';;...'d0KKKKOddxkd:';xOl'cxkxdoc,..,oxoc;,,,,,,;:lx0KOdllld0KK0o.....:kKKKKk,...;kKKd'..cOOd,...ckKKKKKOdlcclkKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKx,........;kKO:c0KOocokkxoc:;;;;cllc,...:x0KKKKKOdlllcldOk:..;;,,...,cdko'...;ccc:,....;dx;...;kKKKd......'lkKKx,...,kKKk;..':;...;d0KKKKKKOdllloOKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKK0d,.......,xKx,:OKK0xc;codkkkkxoc;,..,:d0KKKKK0xxO0000Oxl,..,;::cldxOKKO:...lOKKKKOd;....c;...,xKKKx,.......,lOx,...,xKKOc......;dOKKKKKKKKK00O00KKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKOo:,'....l0x';kKKKK0xoc:::ccc:::ldkO0KKKKKKK0o'':loc,.'ldk00KKKKKKKKK0l...c0KKKKKKd'...;:....dKKKO:...:l'...,c,....dKKKo'....'okkkO000KKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK00kdc,.'c:.'dKKKKKKKK00OOOO00d:ckKKKKKKKKK0o'.;x0d,.l0KKKKKKKKKKKKKKo...,ldxxxdc,...'od,...l0KK0c...l0kc.........l0KKk;.......'',,;cloxO0KKKKKKKKKKKK    //
//    KKKKKOdk0KKKKKKKKKKKK0OO0KKKKK0000Okkdlodl,c0KKKKK00OOkxxdoc'.;xKKKKKKKKKk:..:kKx,.o0KKKKKKKKKKKKKKx,............;lk0k;...;OKK0o...;OK0x:.......:OKKO:...,odolc;'.....,:oOKKKKKKKKKK    //
//    KKKKKklo0KKKKK0kxxxxkOxoox0KK0xoxkoldxkOKO:;xkxolc::::::cccloxOKKKKKKKKK0l.,::kKk;.l0KKKKKKKKKKKKKKO:...:ddddddxk0KKK0c...'xKKKd'..'dKKK0d;.....,xKK0c...l0KKKK0Okdl:::cdOKKKKKKKKKK    //
//    KKKKKkloOKKKK0xllkkdloxkdlok0OocxOocdxO0K0l.';:ccodxkO000KKKKKKKKKKKKK0Od,.lkdkKO:.c0KKKKKKKKKKKKKK0l...cOKKKKKKKKKKKKd....o0KKx,...l0KKKKOo;...'dKK0o;;lkKKKKKKKKKK0000KKKKKKKKKKKK    //
//    KKKKKkloOKKKKKkllkK0xllk0kolddllx0dclxO0KKk;'o0KKKKKKKKKKKKKKKKKKKK0xl:;,.;kKKKK0l.;kKKKKKKKKKKKKKKKd'..;kKKKKKKKKKKKKk;'',o0KKxc::lkKKKKKKKOxoodOKKK0000KKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    KKKKKkld0KKKKK0xlokOxloOKKOxlcclk0dcokOOO0Kx;l0KKKKKKKKKKKKKKKKK0ko;..,lc:x0KKKKKx,.:k0KKKKKKKKKKKKKOocldOKKKKKKKKKKKK0OkOO0KKKKK00KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    KKKK0xlx0KKKKKK0kddddxOKKKKKOxdxO0xddxxxk0K0d:xKKKKKKKKKKK00Okxl:'.':dO0OOKKKKKKK0d,.,o0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    KKKK0dlxOOOOkkkO0KK00KKKKKKKKKKKKKKKKKKKKKKKOlckOOOkkxdolc:;,,,,;:ok0KKKKKKKKKKKKK0x;..ckKKKKKKKKKKKK00OkxdoodooolloxkO0KKKKKKKKKKKKKKKKKKKKK0OOKKKOdlx0KKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    KKKK0xodxxkkkkk0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKkc;;;,,''...,,'cxkOO0KKKKKKKKKKKKKKKKK0k:..;xOOOkxolccclcc:,'.',;;:c:'':c;;:dOKKKKKKKKK0OOOKKKKOl',lkkc..c0KKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    KKKKK00KKKKKKKKKKKKKKKKKKKKKKKKKKKK0Oxdlc:lkKK0Okxxkkxddool;,o0KKKKKKKKKKKKKKKKKKKKKKOl'..',::cllodxxxdl,...,cd0KOddOOo;..l0KKKKKKKKx;';xKKK0d,..',..'d0KKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKK0Okdl:;'';lo;.oKKKKKKKKKKKKKKKx,.lOKKKKKKKKKKKKKKKKKKKKKK0xolccldOKKKKkl::;:,..;dOKKKKKK0xc;;,l0KKKKKKKOc..;x0KKKkl;...'o0KKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKK0kdoc;,'..';ldO0k;;xK0OxolldOKKKKKK0d,.:k0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKOo,,lolllldOKKKKKK0xlc::c:;oOKKKKKKKk;..':cldO0k;..;kKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKK0kdolc::cloddxkO0KOxl;:ooc;;::;.'o0KKKKKKKk;.,d0KKKKKKKKKKKKKKKKKKKKKKKKKKKKOo;':lc:okO00OO0KKK0d;cko:lkkc:x0KKKKKKd'...,..'oOo'..lOKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKK0OdllllodxO0KKK00Oxdolccll:,'',clc:'.:OKKK00000k:..:dOKKKKKKKKKKKKKKKKKKKKKKK0xl::okx::kKOo;;cdO00K0o:oddkkdc;,;cx0KKKKO:...'...lOOoccd0KKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKK0kl,..,;;;:::codl;;;:loool:;,,'';,,,...,ll:::;;;::'....,lk0KKKKKKKKKKKKKKKKKOkdlldk0KO:;xK0l',lk0Kx::odxO00d;,;ccc:;cx0KKKd;',;:lx0KKK00KKK00O0KKKKKKKKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKK0kdooddl,.'lkOOxl:,...cxxoc:;:clcc;.,oxc...;c;clcc:::loo;....:d0KKKKKKKKKKKKOxdoodk0KKKKd,lOkl,'ckKKKOc.,;,ckx,,cllllll:,:dO00OOO00Okxddolllldxc;o0KKKKKKK00KKKKKKKKKKKKKK    //
//    KKKKKKK0kl::lk00KKk:':kKKKK0Oxl'.'';cllllc;,;lk0k:..;dc.,;,;coxO0KOd;';,.;lk0KKKK0Oxolcok0KKKKKKK0o:xkl;...l0KKKkc,'.;d:':c:;;;cllc,';lk0KOdl:;,'..;lodOx,.,d0KKKK0d:;:x0KKKKKKKKKKK    //
//    KKKK0ko:;:oOKOlcx0KOo',dOkxk0KO:';,'':ll:'.,oxxo,...;:,..':c;,,,;:loc;oOl'..;d0KKOc.'lOKKKKKKKKKKK000OOx;..'xKKKK0kxodd,'::'...,cllc:'.,lxOkkkOOo..;kKKKk;..'::cdOd,..'o0KKKKKKKKKKK    //
//    K0koc:cok0KOkd;.,d0K0x;',,.'dKx,cOO:..:lc;;;::::;:::cll:'.lO0Oxdoc::,.,oxd;...lOKO:.c0KKKKKKKKKKKKKKKKK0dc:ckKKKKKKKKKOc.;c;..';clc:;,...'cx0KKKO:..cOKK0c...,'.'co:..,oOKKKKKK0dc:l    //
//    d:,:dOKK0ko:,'...'o0KKO:...'d0d,l0O:...;cllllllllllllll:'.:OKKKKKKK0Odc,':lo;..cOO:.oKKKKKKKKKKKKKK0dlk00KK0KKKKKKKKKKKkc',;:clll:,';c,....':d0KKd'..o0KKx,..co;,:xOxddx0KK0000k:...    //
//    ':xOOxoc,'..;c:;,..cOK0l...;O0l;xKO:....;llllllllllc;;;;coOKKKKKKKKKKK0kl,.:o;.'dx,'xKKKKKKKKKKxodkx:,;cx000KKKKKKKKKKKK0xc;,;;;;''::co:......:x0Oc..o0KK0dook0OOO00OOOOO0Oo;;:ol,..    //
//    okd:,,,,,,,'',:ll;..c0Ko...c00c:OKO;....;llllllc:;;:lokO0KKKKKKKKKKKKKKK0kc';l,.;c;lOKKKKKKKKK0x:;::::,:odddOKKKKKKKKKKKKK0Okdddolc::c:,.':c,..'lOOdxOKOkO0KKkllkKOc,,;clxx;..,oOxl'    //
//    k:.,:looooolc;,,cc;.':c;,..lOd,cOKO:...';;;,'',;:ldOKKKKKKKKKKKKKKKKKKKKKK0d:;'.;ok00OkOKKKKOxddlclollc;:oddk0KKKKOOO0KKKKKKKKKKKK0xlcccok0Kkc...;d0KKKx,';od:..;kk;..;ddxkd:'..;okx    //
//    l';loooc::::loc,,cc,.'cxx;.,;,:dkd:....',c;..,dO0K0kk0KKKKKKKKKKKKKKKKKKKKKk:..,o0K0o;:dOO0Olcoddllodlc::oddkOKKK0d;,cx0KKKKKKKKKKKK000KKKKK0o::'..:x0KO:........cx:..'codk00x:...co    //
//    c;locc:',dkdccoc',:,,xKKx'.'col:'.'cooldkOc.'dKKKKk:':d0KKKKKKKKKKKKKKKKKKKkooxO0xddc;cloooc;cllooloolllcxKKKKKKKK0l...:x0KKKKKKKKKKKKKKKKKKxcokd;..'lOKd'.coo:..'c:...lO0000Ol::okx    //
//    c;ll;:xdok0x;:oo:';,:kK0o..;c,.';oO0KKKKKx,.,xKKKKOc...:x0KKKKKKKKKKKKKKKKKKKKKKKOd:;lddoll:;ldooodoool:ckKKKKKKKKK0o'..'cx0KKKKKKKKKKKKKKKOllxkkxc...:xO:.cOKx,..,:,...,;:lk0000KKK    //
//    l,cl:ldxkO0o';ool,,;;xK0l...';ok0KKKKKKKOc..,xKKKKKk:...'ck0KKKKKKKKKKKKKKKKKKKKKKd;cddooc:;,cddoodoooc;o0KKKKKKKKKK0d,....:xOKKKKKKKKKKKKKxcokkkkl;,..'cc.,kK0d::cxxdoooddk0KKKKKKK    //
//    k;'colc:::c:,cooc,,''oK0c..,x0KKKKKKKKKKd'..;kKKKKKKk:....;xKKKKKKKKKKKKKKKKKKKKKKx:cool::::;;ldollooo:ckKKKKKKKKKKKKKkc.....;lx0KKKKKKKKKKdldddxdcdkc....,oOKKK000KKKKKKKKKKKKKKKKK    //
//    0x;,:loolc:clol;....,xK0o..;kKKKKKKKKKKO:..:x0KKKKKKKOc...'d0KKKKKKKKKKKKKKKKKKKKK0d:::c::cc:,;oolc:::cx0KKKKKKKKKKKKKKO:.......;lx0KKKKKK0dcodxxolOKOo,...:x0KKKKKKKKKKKKKKKKKKKKKK    //
//    K0kc,,;:ccccc:'.':lxO0KKx,.;kKKKKKKKKKKd..cOKKKKKKKKKKOc..;kKKKKKKKKKKKKKKKKKKKKKKK0Odollc:::;,:ol:;:oOKKKKKKKKKKKKKKKK0o..;c'.....;ok0KKKKOkxxxkkOKKK0x:...'oOKKKKKKKKKKKKKKKKKKKKK    //
//    KKK0xc'.';;,..,lx0KKKKKKO;.cOKKKKKKKKK0c.'dKKKKKKKKKKK0l..'dKKKKKKKKKKKKKKKKKKKKKKKKKKKK0OkxdoccoodxO0KKKKKKKKKKKKKKKKKKx'.:kkc'.....'cdOKKKKKKKKKKKKKKKOo'...:x0KKKKKKKKKKKKKKKKKKK    //
//    KKKKK0OkkOd;;oOKKKKKK0Oxc';xKKKKKKKKKKx,.:OKKKKKKKKKKKO:...l0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0000KKKKKKKKKKKKKKKKKKKKKKKk;.'xK0kc'......,ck0KKKKKKKKKKKKK0x:...'cx0KKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKkxOKKKKK0koc;:lok0KKKKKKKKK0l..';lxOKKKKKKK0d'...o0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0c..oKKK0ko,......'ck0KKKKKKKKKKKKK0d;....;oOKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKOkoc;,;cxOKKKKKKKKKKKKKk;.','.',:oOKKKK0c...,xKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK00OkkkkkO0KKKKKKKKKKKKd..l0KKKKKOo;......'lkKKKKKKKKKKKKKKOl'....;x0KKKKKKKKKKKKK    //
//    KKKKKKKK0Oxdoc,',:oxOKKKKKKKKKKKKKKKKd'.,:::;..cOKKKK0o..'o0KKKKKKKKKKKKKKKKKKKOdx0KKKKKKKKKKKKKK0klccloollccdOKKKKKKK0xkx;.cOKKKKKKK0xl:'....'lkKKKKKKKKKKKKK0kl,...;xKKKKKKKKKKKKK    //
//    KKKKKOxo:'..':lxO0KKKKKKKKKKKKKKKKKK0c.colc;,'lOKKKKKk;.,x0KKKKKKKKKKKKKKKKKKKK0o:d0KKKKKKKKKKKKKx;';coodoooc;o0KKKKKK0l:xc.;OKKKKKKKKKK0Od:....'cdk0KKKKKKKKKKKKOo'..l0KKKKKKKKKKKK    //
//    KKOxc,...':dO0KKKKKKKKKKKKKKKKKKKKKKx,,kKKK0kk0KKKKKOc.,xKKKKKKKKKKKKKKKKKKKKKKK0l,lOKKKKKKKKKKK0c.':ccodoollllkKKKKKKKd,cl.;kKKKKKKKKKKKKK0d,......;cok0KKKKKKKKK0l..l0KKKKKKKKKKKK    //
//    oc,..,:ldO0KKKKKKKKKKKKKKKKKKKKKKKK0c.cOKKKKKKKKKKK0l.,xKKKKKKKKKKKKKKKKKKKKKKKK0x;.:x0KKKKKKKKKO;.,c:',:;''cl:dKK00KKKOc,,.,xKKKKKKKKKKKKKKKx,......',,;lx0KKKKKKKd..oKKKKKKKKKKKKK    //
//    ...;dO0KKKKKKKKKKKKKKKKKKKKKKKKKKKOc.,xKKKKKKKKKKK0o..;d0KKKKKKKKKKKKKKKKKKKKKKK0o;..'d0KKKKKKKKOc.':c;,',,:c;:kK0oldk0Kx;..,xKKKKKKKKKKKKKKK0d'....:kOxoc;:oOKKKKKd.'d0KKKKKKKKKKKK    //
//    ..ckKKKKKKKKKKKKKKKKKKKKKKKKKKKKKO:.'d0KKKKKKKKKKKd'.;:,lOKKKKKKKKKKKKKKKKKKKKKKOc....'d0KKKKKKKKkc'',;::::,,:xK0d'.'l0K0l..,xKKKKKKKKKKKKKKKK0l....o0KKKKOxdOKKKKKd.'dKKKKKKKKKKKKK    //
//    'o0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKO:.'o0KKKKKKKKKKKO:.'lo:,lOKKKKKKKKKKKKKKKKKKKKOl......,xKKKKKKKKK0d:,'',,;cd0KKx,..;xKKKd'.'xKKKKKKKKKKKKKKKKKx,...l00000000OOOOOOl..l0KKKKKKKKKKKK    //
//    d0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKO:.,d0KKKKKKKKKKKKx,..,cl,,xKKKKKKKKKKKKKKKKKKKOl........,ldkKKKKKKKK0OkkkO0KKKOo,..'d0KKKx'..l0KKKKKKKKKKKKKKKKk;...;oooooooollllll;..;kKKKKKKKKKKKK    //
//    0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKOc.;xKKKKKKKKKKKKKKo.......'d0KKKKKKKKKKKKKKKKKOc............'cx0KKKKKKKKKKK0kd:'....l0KKK0o...,xKKKKKKKKKKKKKKKKO:...,cllcllcccccccc;..'xKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKOc.:kKKKKKKKKKKKKKKO:........'cx0KKKKKKKKKKKKKKOc.......'::,.....;lx0KKKKKKOd:'..';::oOKKKK0c....cOKKKKKKKKKKKKKKK0c...,lllloooodddddxo,.'dKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKOc'cOKKKKKKKKKKKKKKO:....;;......;ldk0KKKKKKKK0k:.......,xKKk:'......;lxOOdl;..':ok0KKKKKKKKO:....'d0KKKKKKKKKKKKKK0o...;xOOO00000                          //
//                                                                                                                                                                                            //
//                                                                                                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BEAST is ERC721Creator {
    constructor() ERC721Creator("Strawberry BEAST", "BEAST") {}
}