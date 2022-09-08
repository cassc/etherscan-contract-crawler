// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: mpkoz
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                           //
//                                                                                                           //
//                                                   .',.                                                    //
//                                                .;o0NWO'                                                   //
//                                             'cx00xkNMK,                                                   //
//                                         .;oOKOo;. ,KMK,     'o:                                           //
//                                       .oKKxc'.    ,KMK,     cNk.                                          //
//                                       ,KX:        ,KMK,     cNk.                                          //
//                               'cl;.   ,KK,        ,KMK,     cNk.                                          //
//                           .;oOKOkk;  .:KK,        ,KMK,     cNk.       .:dOko,.                           //
//                        .:x0Kkl,.    .xKWK,        ,KMK,     cNk.   .,lk00dclk00d:.                        //
//                    .,lk00d:.         'dNK,      'ckNNO.     cNk..:d0Kkl,.    .:dO0kl,.                    //
//                 .:d00kl,.      ..     ,KK,  .;oOX0d;'.      cNX000x:.       ..  .,lkK0d:.                 //
//              ,lkK0d:.       'cxKKc    ,KXl:x000KNOc'.       cNXd,.         'OO'     .:dOo.                //
//             .dkl,.      .;oOKOxKNl    ,KWXOd:...;dOKKOo,.   cNk.           ,KK,        .  .lk,            //
//             ..       'cx00kl'..xNl    .:c,.      .lKWWNK0x:'oNk.           ,K0,      .,'  .kNc            //
//            ;OOo;.   :OOd:.    .xNl             .d00xoc'.:dOKXWk.           ,KK,      :Xk. .kNc            //
//            cNXO00xc'...       .xNl        .;:. .:;.       'dNMk. ..        ,K0, :d,  :NO. .kNc            //
//            cNk..cKWXOo;.      .xNl     'cx00x'         .:dOKXWk..kXkl,.    ,KK,.kNl  :NO. .kNc            //
//            cNk. .ONxlkKKc     .xNl .,oOKOd;.      .':lk00x:'oNk.'0NOkK0d:. ,KK,.kNl  :NO. .kNc            //
//            cNk. .OX:  oWx.    .xW0x00kl'.      .;dOK0Oo,.   cNk.'0K; .:d00kkNK,.kNl  :NO. .kNc            //
//            cNk. .OX:  lNx.    .oX0d:.       'cx00xc'.       cNk.'0K;    .,l0WK,.kNl  :NO. .kNc            //
//            cNk. .OX:  lNx. ..  ...         cOOo;.           cNk.'0K;       ;K0,.xNl  :NO. .kNc            //
//            cNk. .OX:  lNx..kKkc'     'cdl. ..               cNk.'0K;       ,KX:.kNl  :NO. .kNc            //
//            cNk. .OX:  lNx.,KNOOKOocoOKOo,...                cNk.'0X;       ,KWx;xNl  :NO. .kNc            //
//            cNk. .OX:  lNx.,KK, 'cxKWWO;. .xK:               cNk..dX0o;.    ,KK;.kNl  :NO. .kNc            //
//            cNk. .OX:  lNx.;KK,    .;o0Xd..kNc               :Kx. .:OWWKxc' ,KK,.kNl  :NO. .kNc            //
//            cNk. .OX:  lWx;xWK,       :X0'.kNc                ...;dOKOocoOKOONK,.kNl  :NO. .kNc            //
//            cNk. .OX:  lNx.:XK,       ;X0'.kNc              ... .ldc'    .'ckKk..kNl  :NO. .kNc            //
//            cNk. .OX:  lWx.,KK;       ;X0'.kNc           .;oO0:         ...  .. .kNl  :NO. .kNc            //
//            cNk. .OX:  lNx.,KW0l,.    ;X0'.kNc       .'cx00xc'       .:d0Xo.    .xNl  :NO. .kNc            //
//            cNk. .OX:  lNx.,KNkk00d:. ;K0'.kNc   .;oOKKOo;.      .'lkK0x0Wx.    .xWo  :NO. .kNc            //
//            cNk. .OX:  lNx.,KK, .:d00kON0'.kNo'cx00xc;'.      .:dOKko,. lNx.     cKKxlxNO. .ONc            //
//            cNk. .OX:  lNx.,KK,    .,lkXk..kWXKOd;.         'x00x:.     lNx.      .;oOXWKc.'kNc            //
//            cNk. .OX:  ,d: ,KK,        .. .kMXd'       .;:. .:;.        lWx.       ...'cx00OXNc            //
//            cNk. .kX;      ,KK,           .kWXKOd:.'cox00d.             lWx.    .:d0O;   .;oOO;            //
//            cNk.  ',.      ,KK,           .kNl':x0KNWW0c.      .,c:.    lNx..,lk00x:.       ..             //
//            ,kl.  .        ,KK,           .kNc   .;oOKKOo;...:dOXWK,    lNKkOKOo,.      .,lkd.             //
//                .oOd:.     'OO'         .;dXNc       .'cONX000d:lXK,    cKKxc'       .:d00kl'              //
//                 .:d0Kkl,.  ..       .cx000XNc      .';d0KOo,.  ,KK,     ..      .,lkK0d:.                 //
//                    .,lkK0d:.    .,oOKOd;.'kNc     'OWNkc'      ,KNd'         .:d0Kkl,.                    //
//                        .:d0Kklcd00kl,.   .kNc     ,KMK,        ,KWKx.    .,lk00d:.                        //
//                           .,lkOd:.       .kNc     ,KMK,        ,KK:.  ;kkOKkl,.                           //
//                                          .kNc     ,KMK,        ,KK,   .;l:.                               //
//                                          .kNc     ,KMK,        :XK,                                       //
//                                          .kNc     ,KMK,    .'ckKKo.                                       //
//                                           :o'     ,KMK, .;oOKOo;.                                         //
//                                                   ,KMXkx00xc'                                             //
//                                                   '0WNOo;.                                                //
//                                                    .,'.                                                   //
//                                                                                                           //
//                                                                                                           //
//                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MPKZ is ERC721Creator {
    constructor() ERC721Creator("mpkoz", "MPKZ") {}
}