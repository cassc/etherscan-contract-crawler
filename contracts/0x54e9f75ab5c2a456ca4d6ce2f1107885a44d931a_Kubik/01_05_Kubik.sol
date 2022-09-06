// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: World.Kubik
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                                                     //
//                                                                                                        .                            //
//                                                                                                 :LdBBBBB7                           //
//                                                                                         .r2RBBBBBBPIr.:Bi                           //
//                                                                                  :vqBBBBBQBS7..     . iQ.                           //
//                                                                          .iUDBBBBBBgji.       ...:::. 7B.                           //
//                                                                   :7PQBBBBBBb7:        ..:::::::::::: JB                            //
//                                                           .iJZBBBBQBR5r.        ..::::::::::::::::::. uB                            //
//                                                    .7IQBBBBBBEs:.       ...:::::::::::::::::::::::::: XB                            //
//                                            .:sdBBBBBQQX7.        ..:::::::::::::::::::::::::::::::::. PB                            //
//                                     .r5gBBBBBBg1i.        ..::::::::::::::::::::::::::::::::::::::::. gB                            //
//                              :vPQBBBBBBdv:         ..:::::::::::::::::::.:::::::.:.:.:.:.:.......:::. QB                            //
//                          PBBBBBMSr.         ..:::::::::.:.:.:.:...:............ .               ..::. BB                            //
//                          BB.         ..:::::.:.......... .             ....::ii77sJ5XPdgRBQBBBBBv.::. QB                            //
//                          iB:  :::::..         .....::ir7LJ2IPPgMBBBBBBBBBBBBBBBBBQBBBRgdq5Usv:vBI ::. BB                            //
//                           Qq  i::.:s2EDQBBBBBBBBBBQBBBQBBBBBBQgEKSus7ri:...                .  :Br .:. BB                            //
//                           BB  :::.rBBqDPKUjv7i::...                               ....:.:.:.. JB: :.. Bg                            //
//                           5B.  i:. BQ                    ........:::::::::::::::::::::::::::. SB..::..Bd                            //
//                           .QY  i:. qB  .::::::::i:::::::::::::::::::::::::::::::::::::::::::. RB..::..BI                            //
//                            BQ  ::: :BI .i:::::::::::::::::::::::::::::::::::::::::::::::::::. BB .::..Bj                            //
//                            BB. .i:. BB  i::::::::::::::::::::::::::::::::::::::::::::::::::.. BB .::..B7                            //
//                            7Bi  ::. UB. .:::::::::::::::::::::::::::::::::::::::::::::::::::..BP ..: :Br                            //
//                             B5  :.  iB2  ::::::::.:.:.:.:::::::::::::::::::::.:.:.:.:::::::...Bg.    :B:                            //
//                             BB   :5BBBQ  i::::....    ...:::::::::::::::::::...    ....:.::: :BBBBEr :B.                            //
//                             jB.sBBBj UB. .i::.  i1DMg5r. ...:::::::::::::..  .7SDZPY:  .:.:. rB: vQBBBB.                            //
//                             LBBBq:   :BS  ::. JBBBP5qBBBQ: ..:::::::::::.. 7QBQBPPDBBBU  ..: jB:    :URBBK.                         //
//                          .PBB1i   ... BQ  :..BB7       .MBR...:::::::::. :BBS        rBBi .. qB. .:..  .YRBBi                       //
//                          BB:     :::. 5B:  iBB            QB:..:::::.::.uBX            LB2.. QB  :::.:..  vB.                       //
//                          :Bi  .:i:::: :BX  iBB:          iBB..:..   ... 1BQ:           rBB.. BB  ::::::.. BB                        //
//                           BB  .i:::::. BB  . 1BBBZuLv2EBBB7 .:...LI57. . .1BBBBD511qgBBBr .. BB  i:::::: :B7                        //
//                           7Bi  i:::::. 2B:  :  :ugBQBQEY: ..:..:BBRRBBi ..  .iUbRQQgq7: ..:..BQ  ::::::. bB                         //
//                            BB  .:::::: :Bq  ::..       ..:.:.. BB    BQ .:.:..       ....::..Bq  i::::.. BQ                         //
//                            2B:  i::::.. BB  :::::.:...:.:.::: .BX .. DB..::::.:.:.:.:.:.::: iBu  :::::: rB.                         //
//                             BD  .i::::. UB:  i::::::::::::::. ZB...: iQL .::::::::::::::::. 7Br .i::::. BB                          //
//                             gB.  :::::: :Bq  ::::::::::::::...Bg .::. BB .::::::::::::::::: 1B: ::::::..BX                          //
//                              B2. .:::::. BB  .::::::::::::.. 5B: :::. IB...:::::::::::::::. PB  :::::: 1B                           //
//                              BB.  i::::. uB:  i::::::::::::. BB ..::: .BX .:::::::::::::::. QB  i::::. BB                           //
//                              .BY. .i::::..QP  ::::::::::::. vB: .....  BB .:::::::::::::::. BB  ::::..:B7                           //
//                               BB   ::.... BB. .:::::::::::. BQ      .QMrB: .::::::::::::::. BB  i:::: EB                            //
//                               iBr         rBi  i:::::::::: vBQqBBBJ.BBgBBE .::::::::::::::..BR  ::.:. BB                            //
//                                BBQBBBBBQgIXBq  ::::::::::..2BBv  BBBq  .BB..:::::::::::::...Bu  . .  iB.                            //
//                                  ..:i7L2SPSBB.  i:::::::::. :bBQvBBE   iBB..:::::::::::::: iBS.v1IIK2BB                             //
//                                            :Bi  i::::::::::.. .rqEBQBQBP: ..:::::::::::::. rBBBBBBQgZX:                             //
//                                             QZ  .i::::::.:......       .Pi ..::::::::::::: IB                                       //
//                                             BB.  i:::::.. :i  ......  IBBQr ..:::::::::::. bB                                       //
//                                             iBi  i::::.. :BBBr  ... .BBg2BBr ..::::::::::. BB                                       //
//                                              BZ  .i:::. :BBqBBBL   sBBqIKIBB7 ..:::::::::. BB                                       //
//                                              BB.  ::.. :QBUI15gBBsEBEUU52IuBBL ..::::::::. BM                                       //
//                                              iBi  ... 7BBqPbZEEDBBBQMRQQQBBQBBv.:::::::::..BX                                       //
//                                               Bg      5QPBBBQBQBQQgQMRDgBBd::i:..:::.:::...B7                                       //
//                                               QQBBBBBMKYrqBBPuI25U522uPBg.     .......:.. iB:                                       //
//                                                 .:i7LISbddDBBBKSXKXSPBBB5s11v7ii::..      rB                                        //
//                                                              BBRKSqBBg:r2bRQBBBBBBBBBBBBBZBB                                        //
//                                                               7BQQBB:               .::7vuIs                                        //
//                                                                 BBP                                                                 //
//                                                                                                                                     //
//                                                                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract Kubik is ERC721Creator {
    constructor() ERC721Creator("World.Kubik", "Kubik") {}
}