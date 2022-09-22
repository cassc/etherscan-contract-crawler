// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Chiara Moreni Editions
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0OOO0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKOxoclcoxkk0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKOdoxkddoccccoxxxxxxxkKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0kOKKkolccccccccccccloxOKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKOoccccccccccccccccclxO000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0OOOOO0KKKKKKKKkddddddolcccoolodolccllldk0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKXX0kkkxocccclkKKKKKKKKOxkkkkkdlcccokkkkdldxoccccok0KKKKXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0kxxdlcccccccok0KKKKKK0xlcccccccccccccccccldxxkdlcccdxxxxxk0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKOxdolcccccccccdkOKKKK00kdoccccccccccccccccccccccoO0xlcccccccclx0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0kdkkollccccccccccccxKKK0OxoolcccccccccccccccccccccccccldOOdlccccccclkKKK0xx000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0kooollcccccccccccccccx0Okollccccccccccc:;;;;;;;ccccccccccldO0xlcccccccdOKKKklodx0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKxlcccccccccccccccccccoO0occccccccccccccc:,'.....',:ccccccccclkxlcccccccclx0K0dcclOXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKOoccccccccccccccccccclkKOocccccccccccccccccc;;,.....,,;cccccccoxocccccccccco0KOocld0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKK0xlccccccccccccccccccclodolccccccccccccccccccccc:;'.....'';:cccldo::cccccccccox0Ooclx0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKkccccccccc:::::cccccccccccccccccccc:::;;;;;:::cccc,'........';:codc;cccccccccclkKklclx0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKKd;ccccccc:'.';:ccccccccc;,:clcccccccc;','....',;;:cc;,,.......,:lko;:ccccccccccd00occlxKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKK0l:ccccccc,....;ccccccccc;..,,;cc:cccccccl:,,'....',;ccc:,,,,,;:clxk;,:ccccccccccx0Ooclx0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKKx::ccccc:;,...,ccccccccol,,...,cc;;cccccccccc:;,;'...',:ccccccccccldl,:cccccccccclx0dclkKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKK0c,cccccc:'...,cccccccccol',;,::ccc;:cccccccccccccclc,...,:cccccccccdd;,loccccccccclkOocd0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKKx,.:cccc:,;,.,ccccccccccl;..;cccccc;:llccccccccccccldkd:...':ccccccclxo,;oocccccccccd0OolkKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKKKKOl.':cccc,...':ccccccccccc;..;cccccc::oxoc::ccccccccccoO0d;..';cccccccdOl.;docccccccclxKOldKKKKKKKKKKKKK0KKKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKKKK0o,.,ccccc,..':cccccccccccc;..,::ccccc:lkdc::ccccccccccco0XOo,..;cccccclOO:'cxocccccccco0KkdOKKKKKKKKKKX0kOXKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKKK0ko:'':ccccc:'.,cccccccoocc:,...':ccccccccodoccccccccccccccodk0kl'.;ccccccd0k::oxxlccccccldO0O0KKKKKKKKKKKkdOXKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKKKK0xc;;;:ccccccc'':cccccloolc;'..''':cccccccccodlcccccccccccccccloxko:,:ccccccx0kc:oOxlccccccoxOKKKKKKKKKKKKKxoOKKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKK0KOo:'':ccccccccc,,cccclolcc;'....,;',cc::clccccoxdc:::clccccccccccllxkocccccccoOKkccoxxolccccldxOKKKKKKKKKKKKkd0XKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKK0O00d:'.'cccccccccc:;loclddlc,.......',',:;',;:ccccddol;,,,;ccccccccccclkkocccccclxOOxlclxOdcccccldkOKKKKKKKKKKX0xkKKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKK00KOl'..'cccccccccc;,dklodlc;.........'...;;..',,,:ccloc:;,,,,;:ccccccccoOklccccccollOklcldxocccccldk0KKKKKKKKKK0ddKXKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKK0xdOK0d,.'',cccccccccc::dOxkOkkko;............''.........'.''''...''',,:llld0KOdlcccccccokOdlcodocccccdO0KKKKKKKKKK0dd0KKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKkoox00o;...;clcccccccccccxKkxOkoxkkkolllccc;'.................';:cc;,;cldO000OO00OdcccccccoO0dccodocccclokKKKKKKKKKK0do0KKKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKK0xllkKKk;...';loccccccccoddOK0ddxoccdkk0KKOddolc,..............:oooxKKKKKOkk0K0xxkKKklcccccccoO0dlcooccccccox0KKKKKKKK0dckKKKKKKKKKKKKKKKKK    //
//    KKKKKKKKXKkocox0KOl..';;cllccccccclokKKKKOkKKOxxxddxxxoldkx:,.............lxkkdxxxxOOxxOKKKKKKKklccccccccd00dcoxocccccccd0XKKKKKKKdcxKXKKKKKKKKKKKKKKK    //
//    KKKKKKKOxdlcclxOOd;.',,clolcccccccccoOKKKK00K0OKX0kkxdocldxdc;;'......',;;:lodlccclkKKKKKKKKKKKOlccccccccok00ookklcccccccd0KKKKKKKkloOKKKKKKKKKKKKKKKK    //
//    KKKKK0xolccccclkk:';,';lolccccccccccoOKKKKxodkdx00KK00Odxkkoccc:'.,:::cccccclxxlcokKOkO00OxookK0dcccccccclx0KOox0xlccccccoOKKKKKKKOocdOKKKKKKKKKKKKKKK    //
//    KKK0kxlcccccccoOx;;;,:ccllccccccccccd0KKK0dclkOollxkxxkd;:olccccc:;;;;;;:cccll;;dO0kollooclodx0KxllcccccccoOK0ddOOdlccccccdKKKKKKK0oclxKKKKKKKKKKKKKKK    //
//    KK0doxocccccclO0l::;;ccccccccccccclx0KKKKKklcoolllod;.'co;..';;;;'.......,:c;';okOkocldO0kxkkk00xxxlcccccccok00ddOkoccccccdKKKKKKK0ocd0KKKKKKKKKKKKKKK    //
//    KKOocccccccclkKklc:,,:ccccccccccclkkx0KKKK0oc'....:oc,;:;'.................'..;;,ldlcldxxxoccd0Od0OlccccccccldOOooOklcccccd0KKKKKKKxlOXKKKKKKKKKKKKKKK    //
//    KKxcccccccclxKklcc,.,cccccccccccddl:lOKOkOOoc;...  .....  ......................  ....''';ccclxk0K0dcccccccccclkdcoOxlcccclkKKKKKKK0O0KKKKKKKKKKKKKKKK    //
//    KKklcccccclx0Kxccc,,:ccccccccccoo;,:cd00kxOxl:'................,:;'....',........... ....,ccccoOKKKxcccccccccccxOolkOocccccokKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    KK0dccccclx0KOlccc::ccccccccllcc;,:cclkKKK0Odc;'...............;cc;...':c;................;cccd0KKKxcccccccccccd0OooOxccccccoOKKKKKKKKKKKKKKKKKKKKKKKK    //
//    KKKklcccclkKKxlccc:colccccclddcc:;ccccd0KKKKOl:;........... ...:lc'....:cc;... ...........,cco0KKKKOdlccccccccclkKkd0xcccccccoOKKKKKKKKKKKKKKKKKKKKKKK    //
//    KKX0occcccoO0oclccclddccccclolccc;:lcclkXKKKKOdl;..........   .:lc'..';:cccc'  ...........,clxKKKKKX0occcccccccd0X0kOkccccccccok0KKKKKKKKKKKKKKKKKKKKK    //
//    KKKKklcccccx0xlcccccokOdlcccccccc;:lcclkKKKKKK0o:;........... .,codc:cdkxooo, ...........':coOKKKKKKxlcccccccclkKKK00xccccccccclx0KKKKKKKKKKKKKKKKKKKK    //
//    KKKKKxccccclkOoccccclkK0dlcccccccccccccd0KKKKKKOoc;..............;dkOO0kl:,..............,coOKKKKKKKxllcccccccoO0KKKOl::cccccccclok0KKKKKKKKK0KKKKKKKK    //
//    KKKKKklcccccoOxccccccox00dcccccclllcccclkKKKKKKKKOo:,'............';clol'..............,;ldk0KKKKKKKOxdlccccclxkk0KKOc',cccccccccccdKKKKKKKK0OKKKKKKKK    //
//    KKKKKKklcccclkkddocccccd00xlcccclolcccccoOKKKKKKKKOdlc;,,,......cocllo0Kdccc,.......',;cdO0O0KKKKKKK0kdlccccco0XKKKKd'..:ccccccccccox0KKKKKKKKKKKKKKKK    //
//    KKKKKKKxlccccokOOOocccclok0OdlcccccccccccoOKKKKKKKKKOxollc;,'.'dK0kOOOKKOkOKOo:',;;;:cokOOKXKKKKKKKX0kOxlccldOKKKKX0c...,ccccccccccccd0KKKKKKKKKKKKKKK    //
//    KKKKKKK0xlccccoOOOkocccccldOOOkollccccccccox0KKKKKKKKK0xollc::;ckKKKKKKKKKKXOolccccclxkO00KKKKKKKKKKK0KKkoxO0KKKKKKk;....;ccccccccccclx0KKKKKKKKKKKKKK    //
//    KKKKKKKK0xlccclkK0Oxoccc::cooxO0OoccccccclllokKKKKKKKKKK0Odlcccclk0OkOOO0K00dccccclodOKKKKKKKKKKKKKKKKKKK0Ok0KKKKKKl.....':ccccccccccclokKKKKKKKKKKKKK    //
//    KKKKKKKKK0dccclOKKKKklcccclodloOOxocccccclddllx0KKKKKKKKKKKOxoodddoc:clld00Odcccldx0KKKKKKKKKKKKKKKKKKKKKK0OO0KKKKO;......;ccccccccccccclkKKKKKKKKKKKK    //
//    KKKKKKKKKK0dddlkKKKXKdccccccooxKXK0xoccccclddccoxOKKKKKKKKKKX0OOdldkxocccoddddkxOKKKKKKKKKKKKKKKKKKX00KKKKKOkOKKKKd'......,ccccccccccccccoOKKKKKKKKKKK    //
//    KKKKKKKKKKK000O0KKKKKklcccccclok0KKKOxlccccodddlcldk0KKKK0kddk0OkO0XKOkkkkkkOKXKKKKKKKKKKKKKKKKKKKKKK0KKKKKkod0KKO:.......'cc::cccccccccccoOKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKKK0dlcccccccclodOKKKOdlccclk0koloOOOKKK0xcclx0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKOdclOK0l........',,:cccccccccccccoOKKKKKKKKK    //
//    KKKKKKKKKKKKKKO0KKKKklccccccccccccdkOK00OdlccokkkolxO0KK0dlccclok0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKkdddkKx,........',:cccccccccccccclxKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKK0dccccccccccccccclxdx00dlcccdkdlcd0X0dcccccccloOKXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKk;.........,cccccccccccccccco0XKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKXklcc:;ccccccccccccccokdddlcccoOkooO0xccccccccccldxxOKKKKX0kx0KKKKKKKKKKKKKKKKKKKKKKKKKKKKK0x;.........,ccccccccccccccccco0XKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKK0dccc,':cccccccccccccllllxdlcclk0xxxolccccccccccccccldddddddk0KKKKKKKKKKKKKKKKKKKKKKKKKK0Odl,.......',:ccccccccccccccccclxKKKKKKKKKK    //
//    KKKKKKKKKKKKKKOOKK0occc,.;ccccccccccccccclx00dlldOkddl:cccccccccccccccccccldxk0K0KKKKKKKKKKKKKKKKKKKKKKKOocc;...'...',:ccccccccccccccccccdOKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKOOKK0occ,..,ccccccccccccccclk0Kkok0Od:;:ccccccccccccccccccccoxoldxk0KKKKKKKKKKKKKKKKKKK0ko:,';'...',,;ccccccccccccccccccldx0KKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKKklc:'..'cccccccccccccccldOOxxko;,'.,;cccccccccccccccccccclccclx0KKKKKKKKKKKKKKKKKKkl;,;c:::;;',cccccccccccccccccccldOKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKKOlcc,...;olccccccc::ccccokOoc;........',:cccccccccccccccccccccoxddkKKKKKKKKKKKKK0xol;:ccccccc::cccccccccccccccccccok0KKKKKKKKKKKKKKKK    //
//    KKKKKKKKKKKKKKKKOocc;''..ldlcccccccccccccll;..............'';cccccccccccccccccldolx0KKKKKKKKKKK0xc,:cccccccccccccccccccccccccclldkO0KKKKKKKKKKKKKKKKKK    //
//    KKO0KKKKKKKKKKKOoccc,...'loccccccccccccc,.....................';:ccccccccccccldolxKKKKOOKKKKK0kl:;;ccccccccccccccccccccccccloox00KKKKKKKKKKKKKKKKKKKKK    //
//    0KKKKKKKKKKKKKOoccc,....,cccccccccccccc,..............,,'''.....,ccccccccccccddlcdOKKKOx0KKKOo:,:cccccccccccccccccccccclddxOKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    kKKKKKKKKKKKK0dcc:,.....;cccccccccccccc,.....  .......;cccc:,,...:cccccccccclkxlcclk00OokXKOo;;cccccccccccccccccccccoxxOKOxxxOKOOKKKKKKKKKKKKKKKKKKKKK    //
//    kKKKKKKKKKKK0dcc:'......;ccccccccccl:,;,....   .......;ccccccc:;'':cccccccccokdcccclodookKkl::ccccccccccccccllcldkxoldxxdocclkKOOKKKKKKKKKKKKKKKKKKKKK    //
//    kKKKKKKKKKK0xccc;......,ccccccccclc:'';,...    ....,:,,:ccccccccc:ccccccccccoOxccccccclx0Ol;:cccccccccllllokkkdlodoolllloxxokK0O0KKKKKKKKKKKKKKKKKKKKK    //
//    k00KKKKKKK0xcccc,......,ccccccccl:'..,,....    ...':ccccccccccccccccccccccc:oOxcccccccd0Ol;:ccccccccodk0OkkxollloodO00000KK0K0kOKKKKKKKKKKKKKKKKKKKKKK    //
//    kxkKKKKKKKx:,:l:'......,ccccccl:,...','...   ......,cccc;:cccccccccccccccccclkOoccccclk0d::cccc:cclx0K0kdlccccclx0KKKKKKKKKKKkOKKKKKKKKKKKKKKKKKKKKKKK    //
//    xOkk0KKK0kl',cl:'......,cccccc,.....'...............',,'.',:ccccccccc;;ccccccoOklcccco0Oocccc:::clkKOxocccccccclx0KKKKKKOk0X00KKKKKKKKKKKKKKKKKKKKKKKK    //
//    oO0OOOKKOd;.;ccc,......,cccc,......''.......... ............,:cccccc:'':ccccccokoccclx0xccc:;:ccdO0klcccccccccclOKKKKKKOdxKKKKK0O0KKKKKKKKKKKKKKKKKKKK    //
//    cxK0dlkkoc..;;;:'......,cc:. ....''............  ..............';:::,..,codolccodlcclkOoc:;,;cccxKklcccccccccclx0KKKKKkdk0KKKKKKOOKKKKKKkx0KKKKKKKKKKK    //
//    cdK0ocllc;.,;.',.......,c:. ...'...............   ......................;lodoccclccccodc,',;;cclkOocccccccccclx0KKKKK0xlo0KKKKKKKKKKKKKKKOOKKKKKKKKKKK    //
//    coOklcccc'.,'.'........,c. ..'.................    .....................,ccccccccccccc;..,:;:ccdkocccccccccccok0KKKOkdccxKKKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//    ccoocccc:..,'..........,,......................     .....................;clcccccccc:,..':;,:ccddccccccccccccodx0KOoccccd0KKKKKKKKKKKKKKKKKKKKKKKKKKKK    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CME is ERC1155Creator {
    constructor() ERC1155Creator() {}
}