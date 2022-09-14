// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Not Today V2
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////
//                                                            //
//                                                            //
//                                                            //
//                 ███╗   ██╗ ██████╗ ████████╗               //
//                 ████╗  ██║██╔═══██╗╚══██╔══╝               //
//                 ██╔██╗ ██║██║   ██║   ██║                  //
//                 ██║╚██╗██║██║   ██║   ██║                  //
//                 ██║ ╚████║╚██████╔╝   ██║                  //
//                 ╚═╝  ╚═══╝ ╚═════╝    ╚═╝                  //
//                                                            //
//         ████████╗ ██████╗ ██████╗  █████╗ ██╗   ██╗        //
//         ╚══██╔══╝██╔═══██╗██╔══██╗██╔══██╗╚██╗ ██╔╝        //
//            ██║   ██║   ██║██║  ██║███████║ ╚████╔╝         //
//            ██║   ██║   ██║██║  ██║██╔══██║  ╚██╔╝          //
//            ██║   ╚██████╔╝██████╔╝██║  ██║   ██║           //
//            ╚═╝    ╚═════╝ ╚═════╝ ╚═╝  ╚═╝   ╚═╝           //
//                                                            //
//     __________________________________________________     //
//    [                                                  ]    //
//    [                                                  ]    //
//    [ ---------- NO BULLSHIT.  NO TOXICITY. ---------- ]    //
//    [            NO GREEDY, LYING FOUNDERS.            ]    //
//    [                                                  ]    //
//    [ ------------------------------------------------ ]    //
//    [                                                  ]    //
//    [    MINT:     1 - 2100  :  FREE! FOR OG HOLDERS   ]    //
//    [    MINT:  2101 - 4200  :  0.013 FOR OG +PUBLIC   ]    //
//    [                                                  ]    //
//    [    MAX 10X PER WALLET  |   PUBLIC MINT TIME:     ]    //
//    [    0.013 ETH PER MINT  |   NOT YET DISCLOSED     ]    //
//    [                                                  ]    //
//    [             ALLOW-LIST REQUIREMENTS:             ]    //
//    [             HELD V1 NFT AT ANY TIME,             ]    //
//    [             NO MATTER DURATION, TIL              ]    //
//    [             THIS CONTRACT WENT LIVE.             ]    //
//    [                                                  ]    //
//    [ ----------------- MORE DETAILS ----------------- ]    //
//    [                                                  ]    //
//    [   IMMUTABLE, KICK-ASS, HIGH-F*CKING-RESOLUTION   ]    //
//    [   ORIGINAL ARTWORK. DECENTRALIZED STORAGE,  ON   ]    //
//    [   IPFS AND ARWEAVE. LOADS FAST & LOOKS F*CKING   ]    //
//    [                   INCREDIBLE!                    ]    //
//    [                                                  ]    //
//    [   10%  ROYALTIES             CC0 ARTWORK         ]    //
//    [   4% - DEV FUND              PROPER LAUNCH       ]    //
//    [   4% - DAO TREASURY          NOTTODAYCLUB.COM    ]    //
//    [   2% - ST. JUDE              NOTTODAY.IO         ]    //
//    [                                                  ]    //
//    [   FOR THE COMMUNITY.         FOR THE CHILDREN.   ]    //
//    [ ________________________________________________ ]    //
//                                                            //
//                                                            //
////////////////////////////////////////////////////////////////


contract NTCv2 is ERC721Creator {
    constructor() ERC721Creator("Not Today V2", "NTCv2") {}
}