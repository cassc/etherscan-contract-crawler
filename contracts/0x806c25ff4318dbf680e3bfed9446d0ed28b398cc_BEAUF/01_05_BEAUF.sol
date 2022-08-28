// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BEA URRUTIA
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                          //
//                                                                                                                                          //
//                                                           .;:c;.        .;c:;.                                                           //
//                                               .;::.       c0c,'          ',l0c       .::;.                                               //
//                                       ''.    .xO:'        ;k,              ,k;        ':Ox.    .''                                       //
//                                   ,clclkl     :k,  '.     .xc   .;;;;;;.   cx.     .'  ,k:     lklclc,                                   //
//                                  .xO,  ,k:    .dd. lx.     od   .,,,,,,.   oo     .xl .dd.    :k'  ,Ox.                                  //
//                                   .dd,:lxc  .'.;k: 'k:  .,.:x.  '::::::'  .x:.,.  :k' :k;.'.  cxl:,dd.                                   //
//                                    .x0l'':cccxk;lk. ox. 'Ol'x;  '::::::'  ;x'lO' .xo .kl;kxccc:''l0x.                                    //
//                      .c,            .xo..;'.  ox:kl ,Ox:cl'.dl  .''''''.  ld.'lc:xO' lk:xo  .';..ox.            ,c.                      //
//                       ,oo.      .:c. .xo.   .;dO:ck, ox.    lx.          .xl    .xo ,kc:Od;.   .ox. .c:.      .od,                       //
//                         ;dc. .;ool'   .xo..dkl,. .dd.c0o;:::lc.          .cl:::;o0c.dd. .,lkd..ox.   'coo;. .cd;                         //
//                      .,. .cd:,kO'   ',..xl.ck,  .;dkl:c;'..                  ..';c:lkd;.  ,kc.lx..,'   'Ok,:dc. .,.                      //
//                    .ldddc. .odcdxccodkd..xl.x0l:c;'.                                .';c:l0x.lx..dkdolcxdcdo. .cdddl.                    //
//                   ,dc. .ok;  ,oddd:. .lk;lOoc;.                                          .;coOl;kl. .:dddo,  ;ko. .cd,                   //
//                   ..   'od,   :Okc.   'kkc,.                                                 ,ckk'   .ckO:   ,do'   ..                   //
//                       :0l   ,oo'.cd:;cl;.                                                      .;lc;:dc.'oo,   l0:                       //
//          'ooc.     .,..coc..ckc. .oOl.                                                            .lOo. .cxc..coc..,.     .coo'          //
//         cx;.:xd' .cx;   .:dl,'coloc.                                                                .coloc',ld:.   ;x:. .dx:.;xc         //
//        .,.  'xo. :Od.  :c. ;oocdd.         ,'                                              ',         .ddcoo; .c:  .oO: .ox'  .,.        //
//             :xo:...cookk'   .dO;           ck'                                            ,k:           ;Od.   'kkooc...:ox:             //
//               'cllc,..:llc'.lo.         .. .kKl'                                       .,oKx. ..         .ol.'cll:..,cllc'               //
//                  .;lll:'.:xOc           ,:. .kXxccl;.                              .:lcckXx. .:'           cOx:.':lll;.                  //
//                ;l;'..'cllod;    .;'      ,l:..:l,.,oxc.     .,,.                 .cxo'.,l:..:l'      ,,     ;dollc' .';l;                //
//               ;kl:ldxl:,lO:      cKOdoodddOXKkoll;. 'dx,   :0WNkodkxd:.         ;xd' .;llokKXkdddoodOK:      :Ol,:lxdl:lk;               //
//      .ldllc;..do  .dd,:d0c       .c0WKdcc;,,,;cdkkd,  :kd. .':Od.;ccokx.      .dk;  ,dkkdc;,,,;clxXN0:        c0d:,dd.  od..;clldl.      //
//      :k;.,xX:.xdc;dk'  lo.         .;llldoc,..  .:dOx:'xW0:   ;k,  ..,ok:.  .cKWd'ckOd;.  ..,codlll,.         .ol  'kd;cdx.:Kx,.;k:      //
//     .xk'..dx.  .,:loccdx.          .cc::coxkxl;.   .ckKWWx'   .dc.''',:clc,..,xWWKx:.   .:oxkxoc::cc.          .xdccol:,.  .xd..'kx.     //
//     .:llclOklc:,'.. .;Oc            :OWMWWXkdoolool;..,xX0;   ,;c:'cllc;. ...:0Xx,..;looloodONWWMNk;            cO;. ..',:clkOlcll:.     //
//          .,;,;:cllcclkx.             .;oOXNOc'. .':oxd;.;OXd. .:x; ..:kOo. .xXk,.:ddo:'. .'cONXOo,              .xklccllc:;,;,.          //
//          .dl        .xl                  .,:ll;'.   .:O0lc0WO,.o0;   .xk' ,0WOco0O;.   .';ll:,.                  lx.        ld.          //
//          .Oo   'o'  .d:                 .;;...  .';,. oNKKWMMK;.o0:,lkx. :XMMWKKNl .,,'.  . .,;.                 :d.  'o'   oO.          //
//          .xklllxKd;;ok,                  'x0KKdcc:.   :KccNMWN0:.oKXWO. c0NMMX:lK;   '::cd000k,                  ,kl;;dKxlllkx.          //
//           ..',,o0x:cc,                    .;x0Oo;.  . '0o,0NXKko'.xKO; ,okKXN0,oO. .  .;oOKk:.                    ,cc:x0o,,'..           //
//                ,k: ...                       ',;cllc'  ok;x0:l0x' ':'. ,x0c:Kd;Ol  'ccc:;,'.                      ... :k,                //
//          .:llllxKxcldd.                     .:xOK0o,   ,Ooc0: :KO'    'O0; c0:dk'   ,oO0Ox:.                     .ddlcxKxllll:.          //
//          .Ox'..cO;  'x;                       .:ll:'.:' :Olox. ;KK:  ;K0, .xllO; ';.':loc'                       ;x'  ;Oc..'xO.          //
//          .ko   .,.  .dc                          .,okl.  :kllc. ;KXOkX0, .lloO;  .lxl'                           cd.  .,.   ok.          //
//           ;,   ..';:lOd.                       .:xKKk;';. ;Ol;:. cNMMX: .:;ok, .,.;kXKx:.                       .dOl:;'..   ,;           //
//      ..';:clllclllc:,cx,                         ..',cxl. ;x; ;, :NMMX; ;, ;x, .lx:'''..                        ,xc,:clllccllc:;'..      //
//     .dklcc0k'.    .,:lOo                           'col,'co' .:..xW0xKd .:. ,o:.,ldc.                           oOl:,.    .'k0cclkd.     //
//      od.  lO'.:ccckOc.,d:                              .,,  .c' ,0K:.dO. 'c. .,,.                              :d,.cOkccc:.'Ol  .do      //
//      'kxlldx,'Od. ,k:  lk'                                 .l,  cNk. lX;  ;l.                                 'kl  :k, .dO',xdllxk'      //
//       ';'..   lx. 'k0lclxd.                               .l;  .dWo  :Xl . :l.                               .dxlcl0k' .xl   ..';'       //
//               .ddclc,..,oOd.                             .lc ...kN:  ;Xd ...ll                              .dOo,..,clcdd.               //
//                ..  .:lll;,xx.                            lx..;.'0X;  ;Xd .;.'kc                            .xx,;lll:.  ..                //
//                .,cllc'.,coloo,                          '00;c; '0X;  cWd  ;c:0O.                          ,ooloc,.'cllc,.                //
//             .:llc;..,lOk;.  'oc.                        .:,'o: 'OWc.'xMo  ;o,,:.                        .co'  .;kOl,..;cll:.             //
//             cKl  'loc,;dc.  ,dko'                          ,OO,.xMklxKN: ,OO,                          'okd,  .cd;,col'  lKc             //
//        .lc. .xO' ,ko.  .'.;oo,,xOl.                        '0k. lWWNWW0' .OK,                        .lOx,,oo;.'.  .ok, 'Ox. .cc.        //
//         .odlol,.  .lc  .:dl'.co;.;oc.                       ,.  '0MMMWl   ';.                      .co;.;oc.'ld:.  cl.  .,loldo.         //
//           ,;.         :Oo.  lO:  .okoc,                          :XMWk.                          ,coko.  :Ol  .oO:         .;,           //
//                       .od;   ,ooldc. 'coc.                        lko'                        .coc' .cdloo,   ;do.                       //
//                   ,:.   c0c   :kk:.   'kkooc.                      .                       .:ookk'   .:kk:   c0c   .:,                   //
//                   .lxc,ldc. 'oolxkdl,:kl.cxcdxl;.                                      .;cxdcxc.lk:,ldkxloo' .cdl,cxl.                   //
//                     .ld:. .ldclx:..;od;.cx''ko';c:cc;..                          ..;cc:c;'ok''xc.;do;..:xlcdl. .:dl.                     //
//                         .:dc..xk:.     ck,.xO'    o0cokl::::;.            .;;:::lkocOo    'Ox.,kc     .:kx..cd:.                         //
//                        ;dl.    'cdl.  ck, .;llll',kc cx' .',xx.          .kx''. 'xc ck,'llll;. ,kc  .ldc'    .ld;                        //
//                      .lo'         .. ck,      l0cdx..kO:,.  od            oo  .,:Ok..xdc0l      ,kc ..         'ol.                      //
//                      ..             cO; .clc;:kl:k; :Oc;lOc.xc  '::::::'  cx.cOl;cO: ;k:lk:;clc. ;Oc             ..                      //
//                                    :kdllc,',:oc,xo .xo  .o;;k,  .''''''.  ,k;;o.  ox. ox,co:,',clldk:                                    //
//                                   :x,  ;0d     ck. :k,     lx.  '::::::'  .xl     ,k: .kc     d0;  ,x:                                   //
//                                  .oxl;'ox.    'kc  :c     .dl   .;;;;;;.   ld.     c:  ck'    .xo';lxo.                                  //
//                                    .,:lo'     ok.         'k:   .,,,,,,.   :k'         .ko     'ol:,.                                    //
//                                              .coc:.       :k'              'k:       .:coc.                                              //
//                                                  .        ;dcc;.        .;ccd;        .                                                  //
//                                                              ..          ..                                                              //
//                                                                                                                                          //
//                                                                                                                                          //
//                                                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BEAUF is ERC721Creator {
    constructor() ERC721Creator("BEA URRUTIA", "BEAUF") {}
}