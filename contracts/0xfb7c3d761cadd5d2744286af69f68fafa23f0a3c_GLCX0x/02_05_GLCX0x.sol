// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Glitch Empire
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                   //
//                                                                                                                                                                                                                   //
//                                                                                                                                                                                                                   //
//      JBBBBBQBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBQBBBQBBBBBQBBBBBBBBBBBBBBBBBBBBBBBBBQBBBBBQBQBBBBBBBBBBBBBBBBBBBBBBBBBBBBBQBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBQBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBQBQBBBBBBBBBBi     //
//      BBB BQBQBBBBBBBBBBBQBQBBBBBBBBBBBBBBBQBBBBBBBBBBBBBQBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBQBBBQBBBBBBBBBQBBBBBBBQBQBQBBBBBBBBBBBBBBBBBBBBBQBBBQBBBBBBBBBBBBBBBBBBBBBBBQBBBBBBBBBBBQBQBBBQBBBBBBBQ BBP     //
//      QBB BBQ BBBBQBBBQBBBBBBBBBBBBBQBBBBBBBBBBBBBBBQBBBBBBBBBBBQBQBBBQBBBBBQBBBBBBBBBBBBBBBBBQBBBQBBBBBQBQBBBBBQBBBBBBBBBBBBBBBBBQBBBBBBBBBQBBBBBBBBBBBBBBBQBBBBBBBBBQBBBBBBBBBBBBBBBBBBBQBBBBBBBQBBB BQB BBj     //
//      BBB BBB BB2                                                                                                                                                                                  BBB BBQ BBY     //
//      BBB QBB BBi                                                                                                                                                                                  BBB BBB BBJ     //
//      BBB BQB BQ7                                                                                                                                                                                  BBB BBB BBs     //
//      BBB BBB QBr                                                                                                                                                                                  BBB BBB BBJ     //
//      BBB BBB BB7                              :BBBBBBr   uB:       BB :BBBBBBBBi  :BBBBBQi  rBi    1Q:      vBQJ1I2KL  BBBi   7BBR  qBQZZMQ7   BB  JQB2X5Xbr   BBuj2USM                           BBQ BBQ BBY     //
//      BBB BBB BB7                            iBBi  ..BBi  BBB      .BB  . :BB. . .BB7   .Qs  BBB.i::BBg      BBBY25qP.  QBBB. rBBBB  BBB..iBQB .BB  BBBii:rBB7 .BBg2ISKY                           BQB BQB BBJ     //
//      BQB BBB BQ7                            1BB   ijBBB  BBE       BB     BB    :BB     ir  BBBvUU7BBP      QBB.:iir   BB BBBBB QB  BBBEgQB7  .BB  BQBrBBBB.  .BB::iir.                           BBQ BBB BBs     //
//      BBB BBQ BB7                             .BBBBQQBBB  BBBBBBBB  QB     BB     .BQBBBBB5  BQB    BBv      BBBIPPdDb  BB  BBQ  BB  BQ:       .BB  BBr   :BBU .BBDqPddB:                          BBB BBB BBJ     //
//      BBB BBB BB7                                                                                                                                                                                  BBB BBB BBY     //
//      BBB BBB BB7                                                                .                     ...                                                                                         BQB BBB BQJ     //
//      BBB BBB BB7                                                                                             ......                                                                               BBQ BBQ BBs     //
//      QBB BBB BBr                                                                                                    .....                                                                         BQB BBB BBJ     //
//      BBB BBB BB7                                                                                                        .:::..                                                                    BBB QBB QBs     //
//      QBB BBQ BBr                                                                                     .                      ..::...                                                               BBB BBB BBJ     //
//      BBB BBB BB7                                                                                     :BB:                 .      ..:::.                                                           BBB BBB BBY     //
//      BBB BBB QBr                                                                                       vBBBv          rBBD:           .:i:...                                                     BQB BBB BBJ     //
//      BBB BBB BB7                                                      s: .........                       LBBBBB   QBBBBB.                  ...:i.                                                 BBB BBB BBs     //
//      BBB QBB BBr                                                     d.            iI..                     .MBB uBBB.                           ::                                               BBB BBB BBj     //
//      BBB BBB BB7                                                    ri             B.  .::..                UBBB :BBi.                     ..... :                                                BBB BBB BBY     //
//      BBQ BBQ QB7                                              .S   .B             Bi      ..i:           BBBBQB   iQBBBQ              ..::...    B                                                BBB BBB BBJ     //
//      BBB BBB BB7                                             :.rr   :Xi          BB          .v:      rBBBQ:         .gBB1      .::iXK          .X                                                QBB QBB BBs     //
//      BBB BBB BB7                                            7.  .rI.  uXv        QB            2.    i7.                 vi  :r..    BB         Z                                                 BQB BBB BBj     //
//      BBB BQB BB7                                        .::.i    .:::   :Jr:     Bg            .X                          .L.        BB       sB.                                                BBB BBB BBY     //
//      QBB BBQ BB7                                      :::.  .  .:    i7::  .r:....Bi            vr                        v:           Br     rLg.                                                BBB BQB BBj     //
//      BQB BBB BQ7                                             i..  ...  r7:.       .B:.           .v:                    rv             BQ  .iL7i:i                                                QBB QBB QBs     //
//      BBQ QBB BBr                                           .:7  ..    :.  .::...:    .:::..        rr                 .1.              B7.:ri.:..:                                                BQB BBB BQJ     //
//      BBB BBB BQ7                                        .ii: 7       :.     .ii:rr        ...r7...  :Jr             .r:            ..:.L:  .Yi  i                                                 QBB BBB BBs     //
//      BBQ BBB BB7                                        .    .:    .:     ...   .i.:::.     . :.  .  .7.       .:rvri     ....:::::     .Ur.  . r.                                                BBB BBB BBj     //
//      BBB BBB BB7                                              r  .:    ..:      i      ..:7v: .r               :::   ..  .         :  ::.   ....                                                  QBB BBB QBY     //
//      BBB BBB BB7                                               j.    ...       ::       ..    .J.::..       i:                  ...qv:    .Bi :i                                                  BBB BBB BBJ     //
//      BBB BBB BB7                                              .r7. .          rB      .:.      i   ....:....Lv:..........v5......  : .   .B17  2.                                                 BBB QBB QBY     //
//      BBB BBB BBr                                             ri :v.         i.bi     ::        i.           r v           r:       .  ::i5  u                                                     BBB BBB BBJ     //
//      BBB BBB BB7                                            .:    :r.      :i.     .:          i.         .:  .i          i.:      r.rrX   q                                                      BBB QBB BBs     //
//      QBB BBB BBr                                                    ir:   :r     .:            :.        ::    :.        .: :   ..s2:   ..u                                                       BBB BBB BBJ     //
//      BBB BBB BB7                                                      .: YY    ..              r       ::       :.       r  .2rr::i     7B::.                                                     BBQ BBQ BBY     //
//      BBB BBB BBr                                                        vQ.:rri.               i     .:          i   ..:5r::. r  :      r::2.                                                     BBB BBB BBJ     //
//      BBB BBB BB7                                                       :B  .  .::::::.......  7.   .r:   ......::iI:.. 7       rr      ..:.                                                       BBQ BBB BBY     //
//      QBB QBB QBr                                                      sq.             .......:J ..rr.........      :  :.        .   ..:.                                                          BBB BBB BBj     //
//      BQB BQB BB7                                                    .Dv                      :   :.                ...:                                                                           BBQ BBB BBY     //
//      BBB BBQ BBr                                                    .                        i .:                   rr  ..:..                                                                     BBB BBB BBJ     //
//      BBB BBB BB7                                                                             7..             . ....... .                                                                          QBB BBB BBs     //
//      BBQ QBB BB7                                                           ..           ....r7     .::::::.....                                                                                   BBB BBB BQJ     //
//      BBB BBB BB7                                                             ..:.....:.:..    .7ri::.                                                                                             QBB BBB BBs     //
//      BBB BBB BBr                                                                                                                                                                                  BBB BBB BBJ     //
//      BBB BBB BB7                                                                                                                                                                                  BBB BBB BBY     //
//      BBB QBB BB7                                                                                                                                                                                  BQB BBB BBJ     //
//      BQB BBB BQr                                                                                                                                                                                  QBB BBB BBY     //
//      BBB QBQ BBi                                                                                                                                                                                  BBB BBB BBJ     //
//      BBB BBB BBI                                                                                                                                                                                  BBQ BBQ QBY     //
//      BBB BBB QBBBBBBBBBQBBBQBBBBBBBBBBBQBBBBBBBBBBBBBBBBBBBQBBBBBBBBBBBBBBBBBBBBBBBBBBBQBBBBBQBBBBBBBBBBBBBBBQBQBBBBBBBQBBBQBBBBBQBBBQBQBBBBBBBBBBBQBBBBBBBBBBBBBBBQBBBQBBBBBBBBBBBBBBBBBBBBBBBBBBBBB BBB BQj     //
//      BBB BBBBBBBBBBBBBBBQBBBBBQBQBBBBBBBBBBBBBBBBBBBBBBBQBBBBBBBQBBBBBBBBBBBQBQBQBBBQBBBQBBBBBBBQBBBBBBBBBBBBBBBBBBBBBBBBBBBQBBBBBQBBBQBBBBBBBBBBBBBBBQBBBBBBBBBBBBBBBBBBBBBQBQBBBBBBBBBBBBBQBBBBBBBBBBBB BBX     //
//      rBBBBBBBQBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBQBBBBBBBBBBBQBBBBBQBQBBBBBBBBBBBBBBBBBBBBBBBQBQBBBBBBBBBBBBBBBBBBBBBBBBBQBBBQBBBBBBBQBBBBBBBQBQBBBBBBBBBBBQBBBBBBBQBBBBBBBBBBBBBBBQBBBBBBBBBBBBBBBB.     //
//                                                                                                                                                                                                                   //
//                                                                                                                                                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract GLCX0x is ERC721Creator {
    constructor() ERC721Creator("Glitch Empire", "GLCX0x") {}
}