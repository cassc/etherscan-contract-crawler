// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: JakNFT OPEN EDITIONS
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    doxcoko:,;:lccOKdx0d:;cdxdc:;;okkoc;;l:,.';::lccl:ckxlooll:lkoc::lcclcdd:loc:oOkl,lxl';ooccooodkOdlllol;,cxd:ccll:cxOxxoc:dOolocccclllcollocoxxcccol';    //
//    oxd:lxccoolclldd::dodx:,,cddxc'cxocloollc:c;;oddoclddloc,::ddldc:ccddlodc;lxdc;;:c:oocoxxkdlddldkxl;;;';odOkc;:xd:xKx::c:lolcdo:,:odl'lklcoclOkccc:oo,    //
//    dxlloc:cxkxl::::;oxdk0d,,cc;lo:cloocldcc:,clcd0x:ldlcccccccllcc;lo:loc',:lodoll,:o:':xxdxl:oooddo:okl,:oclxdoooddxdoolc,,ldlldc,':clxol:;lloocl:;;;okc    //
//    kdol:clclccd:,l:;oxdod:';:::lddc,cc,ldlooolllcoololoxlcddolol:,,dx;;dxol:oxdlcloddo;:o:,lxdol::l:lxkxlcloc;lc:dddxl,';odddxdccllodkOdldolc:lc:doollxxo    //
//    lcddlooc:oc:oo::ol,,ldl;;c:cllodlldxolc:col;:lkxcclodlloxx:cl::;cd;'oko;lloxxl;,:do,,cc''ldddcllcclololoxol:cddlc:odccodlloo:,:dkookOollcldo:lo;cdccok    //
//    ;;ldl::odoxk0c.cxdkxdoc:cl;;cclddllol:,lkkxdocoklldc:ccooodl:cl::ollko;cl:;:ldc;:cc:;:c;;:::ccldoc::ododdlclloc::cool;;cc:c:ldodxdoloccc',ccloccodl:;c    //
//    xxkOkx:,ldllko.;ol;:oo;;od:ckxc:;:oddl;;:kkloc,dkc,cc,:llollccxd,,ldxo:,,coodxdoccoldd:';cc::cdkxool:,:olodddxodxxc:oooddo;;kOol:,oo::loc:;;cooldl:::o    //
//    oodllxxol::od:'ldodolcc,;dc:oxo:clodko::cddokl':l;,cc:looxdllc:lc,:l;;cc:cddl:,;ollxxc:c:cdldd:llcokl;dkooxxlo0klddc;',ccoc,:ldxl;,oo;;ooll:;:lollccll    //
//    ool::oollc:ol;';ldo;:;;:::;ooclxd:,,lxkkdlolooll::lll:;olcll;,:clc;;;;::oxc'cl,;lcldxoodddol;;ol;:doloxxl:ol';ccol;;cc,:oloolclxxool,'''loool::cldolc'    //
//    o;,:cc:,:oo:co:;dx;,:;;c:cclolcx0c;:',ldolc;c::c,,l:;:ldc;:do;;oxdc:lc::llcc;,:lolkk:,ldddl;'oOdddddl:col;;dxocol;;,:l;::.:xc;l::c;::;:loolc,:dolox0k:    //
//    ;;cc,:c;';ldloc,l:'lko:c:ldooxxdOOo::lcc;;c;;;'.;olc:,:l;:oxd:,;lc'';:;:lcdko;;oooxddc;cxxc'.:doocld:'cd:cxdlxKklc:ccckx::ooc,;cccllcdxddc:oocdxdodxkc    //
//    :coo:col:cxo:;;ckdll;.'l:;odlldddkl:dkdo;,cllldc:lll:oOOxl;;;:'..':lol;co:cdxxllc,;;lc,cxocol::,;cxd:;lxxol:col:;:cooldc,looc'.cddkl':doc::lxolool:cll    //
//    ol;locodcloc;';oxoc;,;ox:,okl.,occoccoodl,.;oc::::cllkOxc:c:dko:lolc:;:ol:ccc:,,;,::cc'cxoodo::occo:;:lddl:lddc,;:;odcclc::oo:lxO0klcdxl;;:ccoo,;:':lc    //
//    c,;l:;xxllcclccclko;ddcoccOkc,,c;:dxdoo;,,'cc''cdo::ddc:;cdxkdddodoc;:l:c;:ddollloccldoc::l:cdodl:c;,;ol::cllxo;ll:ol,;:olcl::clodlcllxd:ol:lc:::;:oxl    //
//    ;,:o;'oxxdloolc:dOlcdc,dOxol;;l:.;xxdO0d;co::c,;cc::c,;:,ckkdc;lolddlc,,ldlloxxdodc,ccl:;oxc:dxll:.':ddllcokkd;cdoldd;cdxoc;'ccclcx0xdxlc:,,loccc;:cco    //
//    :;,c:,:dxxc,:dlcxOo;;;oxlclcldo::cll::looxxollodl;cl:cdxdxko:::cxdxkl:;;oox0Odllloc:c::lc:xOc;cxdlxdllllolccododllooccccxdldlcoo;cooocdkd,;oolddloxxdd    //
//    ;:c;,:c:ld:;l:,':ddll:;c:ll:xdlodo;lkl::lOKOdllxxo::lxdlocc:;:::cokkkd:;lccoxxc;ldc::,;c;;oxd,,llcc:;coxl,;:;coolol:coc,cdxOl:o:,;;,,:ddlccoodkccdxOx:    //
//    ,ckc,llodc,;odcloodcll:::odcddc::lllllollddlol;:ooloxd:;lloc;;;coxd:ldl';:;,:olcdoloocco:,:dd:;:;,cdccool,,cll:,;cc::clc::lo:cxo:oc;lol;;c:cl:;:ol:::.    //
//    dllolloc:cdodkc:;':oxxddddlodl:;:cc:;:c::lxocc:c:cdlod::ollc.':;cd:cc';c;:odoc,';dOodo;:;:ddldo:',dx,;xxc:clldkc,;:,;lxo:ccoloo:xk;colc:oxdo;.,cc'.,,;    //
//    lc:ddcl::locc:cc,';xOoc:okc:cll,:oooll:,,cccoc,clldolo:;dl;:coo;ckd:cclxo;,'...:olodoollooc;:lc,,clc:lxdl:ld:;cl:,,:dxlcdxOxl::ccolll:;ldxoccolol,';lc    //
//    c;lxddl::col;.,llllccl:;odcclolcdd:oOklcdo;cdxooolodlol:::xOxdo::dkodo,',,;;:c;:dddloOkoc::llcdxlc:;::loc:oo:cloo,,codccxocdl;coc,'.':ll:;clodxdxo''cc    //
//    c,;xolocldl:,.;cox:';;';xl,:oxo,;coxdlcoxoclcdxol:ooclc,,;lkd:;:;cdddl,;lxxxkdddl:,:ol:xkl,,,;cxxlol:;';lodocol:oooxOOxlccloccl:;cldl;lo;;oOxloododdlc    //
//    ,:odlllxdcc;odl:,::;od::doc;lxo:lcco:,,cd;;dl:co:cOkkOocloxkxoolcolcllcclcccldkc,cloxo;;oo:ll;cxx:c::lc::lc::do;oocxl;c::olldd:'.coccldc;:coccclolcc::    //
//    olloddollol:oc:c:llcookdcolldl:coddxo,:ooccokocc',ddodolloooxl:c:oxxolcloclodxddxkxdxdllooooo;;ll;:c:;',ldc:lo::dd;lxdclddxxxo;;od,.clcoo;:o:'cx:'cccd    //
//    ::oo:cl,,oc';:llcol;clodxccol;:xdlkOc;lo;,cdOxoocollxd:co;,;cl;,looxkd:,;cooodolxdlcc:;:;ckkl',c:ckkc:lxxo;.:dko:kd:dxccoc:codl:cloxddoodoxocdxxxddolc    //
//    l:l:'cl::ldc;:lc;cl;:cclc;,cdlclc;:l'.;dllxkxlccdc,cdo:;;',cxxolclo:,'';olcldo:';xkc';lo,':llclccloxdlddoc;lxxOklcc::l:;oc;lc,:clollc::dkdl:loxxlldo;,    //
//    odc:cd:,::odoko:;:loodc';oodkxc:coc;,:c;colc:ccldlc:,:ldkoccolc:lxo:;'cxlclcl:;,cxc;;ckOdcccccdxoloxkOOkko;:;,:;:ddlxd'':cdoc;:ocokd;';dOo,;l::::odl:;    //
//    lo:,ld:';xOxxddoll:cl;',:cddxx;,cl;.,;;:;;xd;:llokdol';loxl;;:;;coccdlloll:,.:kllx:,;coloddxxooxdlolcxkdooodocccokxddo;.,lxdol;;::xxlcdkd:;::::clxOxc:    //
//    ,;:lccxo;ldodddllxococ'';dOdllccol;::;:lcokoldl;cxxo;,lc:c;..:docoollcldolllcoxollcxxdxdldko:lxdccc',ool:ckdl,,xKklloxl,cdo:;o:';oodoccoxx:;oolcllldxd    //
//    c;:dl,cdlc:::::;:lxOklcl;;lo:,,:ccl:loloxdlcll:cdoclloOd:ldl;:xdcloc,:cll,lOOOdod:lOd:lo:'cdoxOdol::lldd;';;;;:kkc,coc,,loolcc,.;ooxkc;clxxxkdoc;clkxd    //
//    oo::oc;dd:llol:;,,,odcxOl';xko;,clol:cclcldllooooolc,;lxkOOdoolod:;;,,ll,;xklcc:do;lol:,',clcdxdkc;oolxx:l:,cclolc,cdc;;xo;dl;;.,ddddccolodooldoc:;c:;    //
//    koc:lo;,lc:oc'..:xo:lc::::clxo:;lxxkkolxdddoxoodl:,coo;:ddxxoc:dxdlcc',;'lkkd:,'cdol:coc',lccl;cxl,'odcc:lo;:oxdxOo;:ldxxo;;:xkl:ll;lxxdoxdoocc::lc,cx    //
//    koddlccclolooll:oOdc::dOocdxo;;cxocoocdx:,ccol:looddl:clooxOx::dc::,cl:;;;dKOdlcoxl::;lko:l:'.,oddl,:cldc'...':c:ll:lodddl:'.cd:';okxxxooxo;ccccodccox    //
//    dxl;:cldccllOO::ol;;:lcol:cooc:lddoo;,::;;coocdl,,:::ccclodlcddxo'.'',:c::odc;;cdo:'.';:dxdooc';c:..;cooc.....'codkxxxkOOdlo;.clcdlcdododd;:doldkkxkx:    //
//    llcododd,;o:cxocc:::coodc,clxxd::l:ll;,..',:odo;,:codccldl:,';ccc,... 'l:cdolcldc'lo,.;::ooloo,..  .,:lx:...   :xkdoodxxkkxxo;.;oxdloc:c:,:oloolooloo;    //
//    :okdlokd;,:lcc:;;:coxxod:'cxdddc;odldd;    .cl;:;:dl;ldxkd:;'......    ,oo:;loll:'... .,:::clc.     .:dd'      ,codxxdxkdoodd:,codxldkc',ooooodxxxdodd    //
//    ;cdlcddl:,:odccxdloxkxdo:;llcldolc;cllc.    .,,:lloo:,ldc:ll,...       .:oxkoc:,..     .;cloxl'. ..  .cc.      ..cxOkxkOlcddodxl:,,,;oc',ldxllolodc;oo    //
//    ;cc:lol;';ddc;clldc;loldkd:,,;dOxxxkkkx,      .':lc;clc::cdd,...        .lkkxo:.       .:::odl;'.     ..        .'oOkxxklldllooc::clc;cl;,,cxdol;:c:ld    //
//    :;',,cdc:k0Oxdxd:;oddlcdkkdccoxkkkkkkkk:        ,l;';c;;loxo;'..        .,okxd:.       .cc;ldxc.      ..         .l0Okkkxdl:ox:'lko;cxdlollxocollddl,,    //
//    ,;,,cccok0dc::x0l:xx::doddlcccdOkxxxkkkc        .,ldlloloxdc,'.          .,ldl.        .;ooccd,       ..        ..cO0OOOkoldo:;coddoxdlxxc,coodoxllxc:    //
//    cccll;::ll::cccddoodc;dkdldxllxxxxxxxkkc.        .cxkOOkxxo:,.     ..     .;:'.         .,dxc,.                  .cOOkkOOl';ll:cd:;okxcldc,lxxxlooxkll    //
//    kddc:lxxkoolclc;o0klxxdxdokkldkkkxxxddxl.  ..     .okkkkxxl;;.    .''.    .'...   ..     .lko'                   .;xkkkkOx:,:l::l::odkxclc:lc;;locool:    //
//    c;l:cl::okklcc,:kOkllxdxoclxddxkkkkkkkkl.   ...    .ckOkkx:'..    .,;..   ...     .;.     'oc.                   ..cxxkdldc:ooolcodl::ccoc:c::cl:,cooc    //
//    oollxo:cdxodxl:cdOdldc:dxodllxxxxxxxxxx:.  .....    .,cxkd:,.    .,::,..   ..     ,l,     .,'.                     'oxxkOOxlxOkl,dkocllcclc,;collllool    //
//    clc;l:,lo''llcooclxl;lc;:oxookOkkkxxxxd,   .'';;.     .;ol;'.    .;;;'..  ..     .:o;.           .      .  ..      .lxkOOkOkOxddc:cdd::oocclol:,cdoold    //
//    ;od:odc;l;;xo,,llld,:do:;clldOOOkkxdxxl.  ....;o:.     .';'.    .:;.'...         ,dxc.          ...     .  ...    .;xOxdkxdxdlll;:oxxlododoooccodc:xxl    //
//    lOkol:cdxc:olllodxdccdxl:loooxOkxxxxdxc.  ....;xd,.      ..     ;dc'...         .lkko,.         .;'    ... ...    .lOOkxOddxcccooc:okkkocccllokkocl:lx    //
//    :c;:lxddx;:olccoddxd;:lcco:lxxkkxxxxxkl.  ..'.:kOc.      .     .lOx;...         ,dkkx:..       .,c'.   ... .'.     .cxdcddlcoocdxxokx;;cdkdcokkdxOd:ox    //
//    loddodlcl,,;:olldlokc;llcllxkxkkxxxxkOc.  ....:OKk:'.          ,xOkl'..        .lxkxxl,.       .:o;.  ......;,.     'll:cccdOd:cdolod:,;dOxcdOxxxkocol    //
//    ,;:llcoxl,ll;:oxxc;dx:lkddkkxkxkxxxkOx'   ..''cxxxo:'..       .oOOkxc'.        ,ddddol:'.  ....;dxc.. .....'l:.    .,ld:,:lkd;.,ool,.codkxc:cdkO0Kklc:    //
//    lo;;,cxo;okxococco:;ddlxddkkkkxkkkkkkl.   .'',coddxd;..       .dkkkkxl'.   ...'lddxxdooc'. ..'lxxxo;.......:dl.     'collool:;,:::c;:ooodOOdl;;cldko;:    //
//    kkccodoloxdloc::;look0OkkOOkkOkOO0kkkc.   .'',cdddxkxc,.     .,xkkkxddl,....':oddxxxddddc,..;ldxdodo,.   .;ldl'     .;odxlcdOOoc:;:lkOxlcdkl,;ccloc;;l    //
//    olc:dxl::lc;cc:;,ldldoldxxOOOOkkOOkkx;    .'',lxxxxxkxoc'.  .cdkkxkxddoc;,;clooooddddxxdoc;:oxxxxxxdl::::loool'.    .cdxxl;::dkc,;::ooclooc:c,;olkx::o    //
//    c:lkxc;ldc:lxdc:cxo:odc:cdkOkkxxxkkkd,   ..'',okxxxxddddo;..cdxxxxkxxkxdoclooooddddooddddoloxkkkxxxxdddddddddl;.    .:dxxl;:;;oc;l:;c;,,ckl:ooolokdcdx    //
//    o:;coo;',;:ccco::xxxdlxc:xkkkkxxkkkxo'   ....'cddddddxddxdodkxxkxxkkkkkxddoooodkkkxdooddddddxkkkxdddddddddoooo;.   ..:odoc:lc;co::od::dclOo;clokdlolcc    //
//    coddc'cooxldxcdlldodoldookkxxdddddddl.   .....:olloooodddxkkkxxkkxxxxxkxxddoddxxxkOOOkxxxkkxddddodddxxdoddoool,.  ...cdlcclodc,cc;;::cxdclol,,cdkdodol    //
//    lox0o;ldxd;;oc:xx:,;;;'.;xkkxdddxxxd:.   .,,'':dddddoooooddddddddxxxkkxddxxddxxdxO0K0Okxxxxdoodddxxddodddoooo:'.    .ldcooox:',:coc:c;cdkdldookxxdodc;    //
//    lkddo;:xkxlc:cloloooc:oxkkkxxxxkkxxxc.   .,,,,cdxkkxxxdoooodddolcldkxdoodddddxxxxkkkkkkkxxdddddxxxddooddddooo:..    .cooxkOkololokxo:''okccxkl;;ldkOl,    //
//    lkko:lxOxlxkl;,'.,cooodxOOOkkkxkkxxxc.   .;,''lxxxkkxxdooooooolc:;;:cclloooddxdolc:;;cdxxdddddxxxddoooddxxddxo;.    .,;,;;clcododdxxc;:cdl:lc;:kOkxc;c    //
//    dodl:dkddoxo;:llxkc::lxkOOkkkxxxdddd:.   .,;',dkdoollcc;,,,''',,''',;::::::;;,'.......','',,,,''''''''',,,,,,''..    ...  ..,loo:,;:coooxdl:cooodoc:dd    //
//    lxl;:dko::xkoclccoxo:ldodxxxxxxxdddx:    .,,,;lc;;,,;;,''..........................               ..............           .,dxxooxoodlodcllldddxkl:cd    //
//    l:coc::l;,lddolllllc;;'.';:;cc::;;,'.    ',,,,...,,,,,'...........                                .                        ';::;:ldolocoko:,:cldoodc',    //
//    c;lxlcoxldx;lOxodxoldo;;oxdol;''..       ...............                                                              ..  .'',dkd:;c:;:lxd:cox0kokO:,c    //
//    :;;oxlxOoxOooocc:oooxx:,ldd0k;......                                           .  ....,,...',,'',,:c,;;..':;.......    ...,;:lkkc::lxc;xOkkkdxklcoloxo    //
//    oxddo::oxdoooodc';cldc,:llcoo;.                              ......  .;:;;'.;c:ccdoccldxxc:oxdc:oclxodx;;codlllc::::c:'';lxxdk0o';lllodloxxxkdc'':lddl    //
//    xdcdxc;;,;,odlkxlcldl;:lcllldoc:'.''.....'';'.'::;l;....:oc:ll:,',;;;ldollocdkdxOkxdkdclkd:oOoll,,,;ddddldOxddooolxOxl:;clcxkddo:cc;:xkl;:c:loc:;;coox    //
//    ccccccc:,;lll;:o:.:Oxloodl:lxxkdlcccod:,:oxko:oOOddoclc,ckxc:lxo,;l;:xklcollodl:lkkkOkkOOOo:codddoccokdoodxddxdoooddodxdl;;coc;odl:;cdd:'';::c:okc';cd    //
//    docllcldo::co:'lx:;cld:'lc:l;cdolodoll:'.:oo:'lkxxd:okc,:okd;,cc,lxdooo:,:dOdcc;;dkxkkxOkllo;,lcco;;ll;:lllcol:oxlldxddxlc;;oc.;olc,,dkdl',dd;:llodold    //
//    lllo:,cl;okoll;cd:',:olco;;loc;ll;locoxddxdol;;:odollodxocdxoc,;loc:lc:l;,lxdcc;:xdxxdddolcolcl,'lo:;'';oOl,:lccl:ll;ll:;,,;loolodkd:lkOo:oo:,coxd:cl:    //
//    xdxdcoxdlcol,:ddllccddloolddlc;cclddodl;:olld:,:lcc:coooc;:clc,'lxookx:clcx0d:loxold;.;::loxxlc;:oxl::::ldoolc:ldll:.'ldlccccxdoo:loc:ll,;lc,..'cdl:cl    //
//    d00lloldOkolodo::cloolcoxolc,;llodolccc;odc:cloc,;;:xklddlooxOOdocdxcccll,:dolloo::::c:;,:odolodolccdollcdoc:dxdlldol:;;lc:,;oolol:xx:c:'ldlcldocllccl    //
//    odxccdodxdldOdl:;:docll:':dklcc,,;lddxdodxc.;kkc;;coooooool;:oc:lxoclddl::dkkdc::cllkdcol;:ddccol,;::lxkccldxllc,,;ldo;,:dl;ldlclloxoolocckx,,dl;:odox    //
//    dllc:ldool:;c:::,:lclxdl;,:olllooloccdkdcodooxo,;cckOoldollcol:clccdollccclodocccoookc.;::clodo:locodcll:l:cddo:'',,cdlccc:lc:lol;ol:k0xodko':kd:ldxlo    //
//    lloxolddooc:,,ccc;;dxdxxl;',:lloo:ldococ;,;oxlc:clccooll;:xoc;;o;.'oddolldl:c:cc::ldo;,locldclolxd;,cl:;ddloc::;::od:;cdc,;codo;cxd:;oxdkkodxol::ocldc    //
//    :;:lc:loclc:,:lcclolldko;:;:d::c,'x0odxoclool;;:oko;lo,.,do;:lloc,;oxdlclc,.'cdoooc,;:col;cdc:occo;:doooodo:;;ol,:clc,ldclooxoclxdlcdkoclllccll:;colol    //
//    d:;lldOl.'lc:lkxcco:cxo:c:;co:;c,'c:;dKO:,ol',:ldxo:ddod:cxlloclddc:cccdl:oodoolccc:c:cc,coodcodoxolll:coc;:cldolodlddoc:cclo:.,cl:;lxxccoolloc,:oxdc:    //
//    :;;oxooo:;xOddoccl:cxd:cdl;:ldd:,:;;cool:;l,;xxc:odcdOdc:odccllodo:,lxddxxdlcodo:cdodxdl:clxxlcxxolc:ccoolc:cdl;cc::ldldoclc,;:cloxkc:o;.:l;;ll;,:llcc    //
//    ::cl:cloo:;ol;cc:c::loc:;:c:lxl'cl,:cc,;::lccxxocc:,:oxdooxklckOdoddook0xl,.,l:;:lkxoxdc:;;:oxdol;:llokklc;;:lc:cod,,ooxOooxxxlodc:llll;;dxllc;cclldo;    //
//    :',;,;cod:,lo:l:;:looddxxl;:ol::oc,ol,,oxodc';ldko,,lcck0kxdoooOOxkkxcod:;;,;clc;lxoodolc:l:,dkdllxkoldxo:col;:od:coll;:dOOxxlcol;;xklldddxlokd:''coc;    //
//    :;:lcoolollooc:lolldl:;dKo;cookxddc:coodd:cccc;lx:.'ol:ddoolll:dOxollcoOdccclcll;,,',:c,'cc;,okoc:lkxcclodlc:,::;::ccc:cldlcllldd,.cd::oxO0dlxkxoccdd;    //
//    Kkxdk0kkdcldoc:lc:cccc:cdkxxxdoll::c;::;;:c,,odk0o';dl,;ldxollclc;looolxdcllccc:ccol;::';dxc,c:',:loolcodoldddl;:c,,clcdoll:;dxdko';:ll::cdko:lkko:lc'    //
//    xd;:oodl,,lxkl:cc;;cc':xxOXO:cxdodxxddd:':ocldcodc;ldl:lxo:ldoc,c:;oool::,l0kdlldxdc:;;;oOxc;:cl;:d::dlc:;lddc,,;clc:::;cxocoocokxolclxdlldxoclxkdlxkd    //
//    ooc;cxdc:;:oc;coldo::ccloxko;:doldo:ldd:.':dkoccc,;oxoclxc;;:o:;dx;;odc:dxllollllllol;cccdlccldo::dddxlllccldc:l:;;,,:lldkkdddolcoxdodxdccoxxoox0kkkkk    //
//    kxo;;ol;;''oo;,:dkdl:oxllddo::lcloxxddol:,ldoc';;'::cdddlcoloo::ox:,lxd::l:,;clc:olcdlcoc;:ododdoddcokc;oodocllxko:;okoodoo;:odl:ldookxddkOdl:.,oxo:cO    //
//    dodocccc:';oookdcclloo;;ldOxclo::odo:oxol:oxc:llcldococ;cdl:ccddlldlcdk:.':looxl'coccdkxlcdk0OocllccdOl:doloo:,loc,:KXdoo::lccllOxolc;:oodxoclcldool:l    //
//    kc;odoocc;;loxdcokdloc:ldldxlc;cdkdcoxdoool::ccdocoo:clcdkxo;lxc',lkxcdx,'lkc,;:lo:,,cdoodkl:dl':c,cxolxl;colxkkd;;ddodoccccdd:cdddddlccclkd:c:co:ox,'    //
//    :lodddo;clooloddldddlcxdc,',':coocloxdlloc,,okood:,lc;codloxccdl,:xdooxxdox0d;:ollll:,cc;cxl'::,;:::ccooddc;:cdOx:cdc:ollxoollc;:c:,:odc;cdc.,dxl:cdl:    //
//    ccc::cddl:c::dkl,clddoko,':l:;cocodxlll;cllcclldoccol;colcod:'co;:odkOkoccool:lxl;cocccl,.lolllclkd:;:oxoc:dx;:l:ldl;:c,:ol:;;:lo:';:coodoll;:dl:odo;c    //
//    :''''colldxc:ooc::colclldko;:lc;codo:c::;;dc:okk:':,;c,;dolxo';o:,clxx::o:cddlcxo,:coOkdc,,;ldxxxxo;;:colc:okccllxoccclcll:c:lxd;;lc;lo:cc;cllddcco:cd    //
//    c;';ccodooodollxo,;:,;lldddd:;c;:lldddllx:'lxodxo:;,,:clc::::..cclocdkdcc:;;lkdl::cloxxo;;lccl::oc,:::clocldkl,,ol:lclococ:xd;cd:,lxo:cxdclocll::c,.;l    //
//    ll,';coc;;,,oxocllclllddodd:';doloolddllolcoo;:olcc;;llllc::oc;::,,cdodxd:'':odc,;:c:,codkOkoc::ol,,.;lc;:ccloc,lol;;xdclccolcloldxoc;coxc,;:cc,:l,,ll    //
//    ;:clc:l:cl,.;lcoxd;;llxkodxc'cOolkxllocck0xooocc;;clldo:ldloOkocol;:oddokxodl;lool::cldlcoc;:ol,:ccddl::coo::od:;c:;oO0dclcoodkxc;,coldd::dxldxooxolol    //
//    odoododdllol::ldkx:,;:doolcloolccc:dkc;;cdccc;coccl:dxl;'ldc:l;;odd:cOOoclclooo;,dxc;ll,':oocc:,lccdocc:;oxxkdldxc:dxllooocodc;:oo,cK0occoxdcloolll;;o    //
//    cloo:;c:;oxol:lcco,;:::;ccdd:..lxl:oxlcoollcl::oodxdxxolc,;ccll,,ldddOOo:cc:cc:;;oc:c'.,;:oOxcc::;;lc:l:.,lldc;c:;cxkxxo:odll:cdlc::oxlcol:lodo;':clxl    //
//    :llld::oxOdlocldoclo:,''loodl::lddcolldo:;loc;cOkoxd:cc:cclxxodl,ldccodc;,:lxo;lo;.,::ccdl;cdl::cdxodko:clclc;;;:lccxkc.'dd::ccc,;:llldol:.':dx:,lkOkl    //
//    oxdoxllkdc:ol;::l:;dl,,;d0Ox:;:;;;ldd;,c,;xl;ccoxOkol:lddllodod:.:dolo:.,::cdoldxo,,col;cxdoddl;odldlcllloloc;oxddo:cOxldxddooddo;:oocllloocldc';cdxld    //
//    :codo:;oOo:xd:c:;cokd;:clxo,:l;cxdloodoc,'ccc:;oocc;ldlldl;:ocllclodoll;;looo:cOdcoc:dxoll,;:,';oc:c;cod::occoloooxo:dxoOddOolddcoooolodc'ckdlldollddl    //
//    dc:lodl:c:lOkddxdlcdkooocll,;dc,coclclolo;c0Kxlodcccodolc;,:;:lool:cooxo:;;:,.;dcokdc;lxlcdl,,;coloxl:llloloxc;:,'cl:oddocloxdlllloddloxxoxOoclc::;:xk    //
//    c::;:odl,,',llldocooddccoxddkko,.lxo;:lodcld:,okccdc:ddddcc::ll;cxlcdxkxc;clc::loOxdl;okxddc;locc::dl:olcl;;:,:l:c;;lll:clcoxocccooodxxoxxol::ccoxxoll    //
//                                                                                                                                                              //
//    JakNFT OPEN EDITIONS                                                                                                                                      //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract JakNFT is ERC1155Creator {
    constructor() ERC1155Creator() {}
}