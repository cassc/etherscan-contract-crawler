// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Butaverse Pass
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////
//                                                        //
//                                                        //
//    罵尻ロマ子様応援パスポートNFT「豚バースPASS」🐷                        //
//                                                        //
//    ▶ButaversePass(豚バースPASS)はロマ子様の活動支援を目的とした応援NFTです。    //
//                                                        //
//    ▶売上はロマ子様の活動費、罵倒DAO主催のイベント運営費に使用させていただきます。           //
//                                                        //
//    ▶豚バースPASS保有者の方は限定イベントに参加、限定NFT配布といった特典があります。        //
//                                                        //
//                                                        //
////////////////////////////////////////////////////////////


contract BUTAVERSEPASS is ERC1155Creator {
    constructor() ERC1155Creator("Butaverse Pass", "BUTAVERSEPASS") {}
}