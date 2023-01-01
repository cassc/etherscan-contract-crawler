// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: At the Concerts
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                       //
//                                                                                                                       //
//                                                     ';,                                                               //
//                                                  'odldk:                                                              //
//                                                 cx:   ,l'                                                             //
//                                               ;xd'      l:                                                            //
//                                              ox;        ,x0c                                                          //
//                                   ;xxo;     lx           ,cl,                                                         //
//                                  '0NxdOOd' :k;             ,o; ',;;'                                                  //
//                                   dWKooKWX0Xd               oXklllc:;ll                                               //
//                                    kWMWWKxoOKd:'            :0o       xo                                              //
//                                     lXNx;:od0NWKOxdl:''';;;lKMO      'xc                                              //
//                    ;o:               kN0OKd 'dOO0KNN00K0OOOxd0k      kO'                                              //
//                 ,' ,,;:              odo0KKOOkdooONXOXNklc::lkc   'okd                                                //
//                ,l;';dc'::;,  ,l'    ,l'  :x0NWX00XKxllddollcc,  ;dKk,                                                 //
//                  c, '   ;;  ;do     lk'     ,ckNWWNOoc:;;:cclolll:cl:                                                 //
//            ckl,,;ll        ;:'      cO,        oNKxod0WWWNXKKKd'';ld0Kc                                               //
//             ,',:,         ';        'c         dO;   ':::,'  ,,   ,,,xo                                               //
//             ,::c:cc,      ,d'       ,l        :O:   ','              d:                                               //
//             dx::olc;';llcckK:       :c      ,;xx  o0KK0Oc   'lxd;   :l                  ';;                           //
//                       ,coxOd:'      ,,     :ON0; cN0c,;o0l ;kN0kO:  c'            ',   '  :l::;'                      //
//                            clc;     c:    ,okKo  kWo    oNXN0c  ll  :              ' ''   ';,';c:cc                   //
//                             ,:c;,;' c,       ;'  lXx    lNMNc   oc 'c              ,;        ,o:,:;                   //
//                               'cc:::oo,  cx,      l0d,':kXXXx;:xx' cc               :;      ,:'',                     //
//                                 cc;;,';:cOW0:      cOO0XO; :OXXx, 'kl               ',:do,  oKlcOk'                   //
//                                    'll;,;:kNO;        ,,    :c,   c0d:,,,         ,c:,',lo;  c' ',                    //
//                                     ':  cOOooc          'dOKNO;   k0c',,;::,',c:cc;'      ;;:l'                       //
//                                     ,o'  ,' ,c          cNMMMWd  ,ko   ',;o0XX0c'           ;'                        //
//                                     oWO;    'l'     oc   d00kl   ;d'      :xko'                                       //
//                                     l0l      c;     cOo'       c:,x;                                                  //
//                                     ::       :c      :O0kollclxKc xo                                                  //
//                                     ;,       ,c        dXMMMMNO:  ox                                                  //
//                                     ,,        c,        ,cccc;    :O;                                                 //
//                                     l:        ::                  cO;                                                 //
//                                    ;kccl,     :l                  cO,                                                 //
//                                        ,dkk;  lO'                 ;0c                                                 //
//                                          'okkccKo                 ,Ok                                                 //
//                                            ':oxkx;              ,okXNc                                                //
//                                              lNd;;  ,clc;;;'':cdd; ,;                                                 //
//                                              ;0c'xxcoc'lOd:lko''                                                      //
//                                              ;l,lKl    cl   ol                                                        //
//                                             oKKO0N0: 'OKl  :0No                                                       //
//                                             cXKolkXx ,xdlolxXXc                                                       //
//                                             'kOxodOl  xOdook0l                                                        //
//                                              dX00Ox, :0dxNMNl                                                         //
//                                              oo   c,,Ol oNM0;                                                         //
//                                            :dkc   c'lNo ':cclolllc;;;                                                 //
//                                         :odo;,;,;dO;,OX0kkxdoollllloddllolc'                                          //
//                                    ,coxKMNOolxOkdo:   ':loodxxOXNXK0OkdkXMMNl                                         //
//                                 d0XWWX0xl:,                    ':::ldk00O0KO;                                         //
//                                 cdol:                                                                                 //
//                                                                                                                       //
//                                                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract IBAAC is ERC721Creator {
    constructor() ERC721Creator("At the Concerts", "IBAAC") {}
}