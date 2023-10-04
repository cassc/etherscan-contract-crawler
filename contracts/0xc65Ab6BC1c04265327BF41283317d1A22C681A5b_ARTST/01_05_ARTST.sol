// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: by Nakayoshi
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////
//                                                                                   //
//                                                                                   //
//        __________  ___________   ______     __________     ___    __    __        //
//       / ____/ __ \/  _/ ____/ | / / __ \   /_  __/ __ \   /   |  / /   / /        //
//      / /_  / /_/ // // __/ /  |/ / / / /    / / / / / /  / /| | / /   / /         //
//     / __/ / _, _// // /___/ /|  / /_/ /    / / / /_/ /  / ___ |/ /___/ /___       //
//    /_/ _ /_/_|_/___/_____/_/_|_/_____/    /_/__\____/  /_/  |_/_____/_____/       //
//                                                                                   //
//    ------------------------------------------------------------------------       //
//    IDSK5KSKSKSKSKXKSKSKSKXKSKXqSqXqXqXqXqXqKPKqXKSXSKXXSKXKSKXKSKXKSKSqXKSXSSb    //
//    SEXSqSqSKSKSKSKSKSqSKSXXKSKXEMQRQRQQQQQRQRQgEXK5KSKSKSKXXSKXKSKSXXKSKXqSX5E    //
//    ID5XXKSXSXSqSKXKSXXKSqSqXqKD27vYvYvLvYLYvYv7XEXPKqXqSKSKXKSKSKXXSXXKSKSK5Sd    //
//    SEXSKSXXXSqSKXKXqSKXKKDgRRQB:               JBQgRgZSKXKXKSKXKSXSKSqXXXKXK5Z    //
//    IZ5KSKSqSKXKXKXqSXXqKZUju2UE:               rP12jJ5EKKXKXXXXSKSXSXXXSKSKSXb    //
//    SdKSXSXXXSKSqSqSKXPEMB       i::::::::::::::      .BMdqXqSXSKSKSKSqXKSKSK5Z    //
//    ID5KSXSKSXXKXKXKXPdKKQ       i::.:.:.:.:.:.:      .QXqdqSqXqSXSKSKSKXqXKSXd    //
//    5EX5KXKSqXKSKXqSKPQ    ::::::::::::::.::::::::::::    BKKSKSXSKXKXKSKSqSKIE    //
//    5D5XSKSqXKXKSqXqXdB    i.::::..............:.:.::i    BbXqXKSKSXSKSKXKSqSXd    //
//    SESSqSKXKSKSqSqKEgB    ::.::                    ii    BDbKqXKXKSqSKXKSKXK5E    //
//    ID5KSKSKSKSKSKKEZQB    :.:.:                    :i    BREdXXSKSKSKXKSqXK5Xb    //
//    SEX5KSKXqSKSKXdD    ..::i   .BQMQMQMRMRMRMQMRQB    ::    RbXKSKXKXqXKSKSX5Z    //
//    5DSKSKSKSKSKXKdQ   .::::r   .BQBBBBBBBBBBBBBBBB.   7r    BPKXKSqXXXKSqSK5Xd    //
//    5EXSKSKXKSKXqSZQ   .::                                   BdXXXKXKXqSXSXSX5E    //
//    5DSKSqXKSXSKSKbB   .:i                                   BPqXqSKSKSKXKSKSXb    //
//    5EX5KSXXKSKSXXZQ   .i:          r:iY1Y   :i:7s5          BbSKSKSKSKSXSXSX5E    //
//    5D5XSXXKSKXKXKdB   .:i          u77RQQ   7vrPQQ.         BPKSKXKSKXKSKXqSXb    //
//    SEX5XXqXKXqSKXZQ    i:    jY.   D2U7js   1qUvvS          BbSXXqSKSKSKXqSX5E    //
//    IDSXSKXKXKSqSqdQ   .:i   .BBr  .BBgvsJ   QBBuvI          BPKXKSKSqXqSXSqSSb    //
//    SdSSKSKSqSXXKXZQ    ::   .ME:   ...      ...             BdXKSKXKSKSXSKSXIE    //
//    ID5KSXSKXKXKXKdB   .:i   .gE.                            BPKSXXKXXSXSKXqSXb    //
//    SEKSKXqSKSKSKXEQ   .::   .gUviiiiiiiiiriiiiiriirsq       BdSqXKSKSKSXSKXX5E    //
//    IZSKSKXKSqSqSKbB   .:i   .ZYdBBBBBBBBBBBBBBBBBQBBBv      BPKXKSqSXSqSKXX5Sb    //
//    5EXSXSXSKXXXKXZQ    :i   .gvXBBQQQQQQQQRQQQQQRQBBBr      BbSKSKXKXqXqSKSK5E    //
//    ID5KSKSKSKSKSKbQ   .ir   .BXEBQQQQQQQQQQQBQQQBQBBB7      BPKSXSKSKSXSXXK5Xb    //
//    SEXSqSKXKSKSXSPZ          r.LBQgMgMgMgggRgggMMBPPB.     .gPSKXqXXSKXKSKSX5E    //
//    2Z5KXKSKSXSKSqKbQBB    77    BQQQQQBQBQQQQQBQBB       BBMbXKXqSKXXSKSXXK5Xd    //
//    SdKSKSKSXSKSXSKXPdQ    ..    KJLLLsLYvYvsLYLYsP      .QPPKKXqSKXqSKXXXXSKIE    //
//    IDSXSXXXSKXqSKSKXqPQBB    77                      iBBMPqSqXKSKSXSKXqSqXXSSb    //
//    SdXSKSXSXSKSKSXSKSqqDB    :.                      :BZqqSqXKXKSKSKSKSXXKXXIE    //
//    IZSXXqSqSKSKSKSXXqKDMB       i.7BQgdKPKqXPPQ      :BgEKKSXSKSKXKXKSKXKSKSXb    //
//    5EXSKSKSKXXSKXKXqqZSPQ       :.iqUuX51UjUuSM      :QqXZKqSKSKSKSKXKXKSKSK5E    //
//    ID5KXKSXXKSKXXSPERB       i:.::    BBBBBQBBB    ii    BMbPSXSKXKSqXKXqSK5Xd    //
//    SEKSXSqXqSqSqXPdbZB       i.:.:    BBQBBBBBQ    ii    BEbdqXKXKSXXKSKXKSXIE    //
//    2D5XSKSKXKXqKEgB    :..:.:....:       BBB       ::..:    BZdKqSXSXSXXKSKSSb    //
//    5dK5qXKSKXqKEZQB    :::::.:...:       BBB       i.:.i    QQEdKKSKSXSKSKSK5E    //
//    2D5XSKXKSKXZq    ..:.:.......::.   :..    .:    ::......    MdXqSqXXSKSKSSb    //
//    5dXSKSXXKSqZE   .::.:.........:    :i.   .ii    i.....:i    BbKSXXKSqXKSX5Z    //
//    IZSKSKSKSKXgd   .:...:...:...::    :::...:.:    ::.:.:.:    QEXKXKXXSKXXSXd    //
//    SdX5KSKXXSKDD   .:....:::::.:.:    ::.:::..:    :.::::::.   BdKSKSKXKSKSK5E    //
//    ID5XXXXKXXSgE   .:.:.:    ::..:    :........::::.:    ::    BEXKXXSKXqSK5Xd    //
//    SEK5qXXSKSKDZ   .:..::    i...:    ::.......vu2:.:    i:.   BdKSKSKSKSKXK5Z    //
//    IZ5KSKSXSKXgE   .:...i    ::.:.:.:.:........::::.i    i:    BZXKXqSKXKSKSXb    //
//    SdX5K5K5KSKDD   .:..::    i....:IUJ.............::    i:.   BdX5K5KSKSXSX5E    //
//    2Z2S5X5X5SSDE   .:...i    :.....:::..............i    ::    BESX5SIX5S5SISP    //
//    5QdbZbEdEdZQQ   :::::i    r::.:.....:::::::::::::i    ri.   BMZdEbZbZdEdZPQ    //
//    ------------------------------------------------------------------------       //
//                                                                                   //
//       / | / /___ _/ /______ \ \/ /___  _____/ /_  (_)                             //
//      /  |/ / __ `/ //_/ __ `/\  / __ \/ ___/ __ \/ /                              //
//     / /|  / /_/ / ,< / /_/ / / / /_/ (__  ) / / / /                               //
//    /_/ |_/\__,_/_/|_|\__,_/ /_/\____/____/_/ /_/_/                                //
//                                                                                   //
//                                                                                   //
//                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////


contract ARTST is ERC1155Creator {
    constructor() ERC1155Creator("by Nakayoshi", "ARTST") {}
}