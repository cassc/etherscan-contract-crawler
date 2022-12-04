// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ButaversePass
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////
//                                                                   //
//                                                                   //
//    ▶「ButaversePass(豚バースPASS)」はロマ子様の活動支援を目的とした応援NFTです。             //
//                                                                   //
//    ▶売上はロマ子様の活動支援、罵倒DAO主催のイベント運営費に使用させていただきます。                     //
//                                                                   //
//    ▶購入していただいた方は「ロマ子様雑談回 in cluster」といったクローズドイベントに参加することができます。     //
//                                                                   //
//    ▶「ButaversePass(豚バースPASS)」は有効期限のあるパスポートNFTです。春夏秋冬、年4回発行します。    //
//                                                                   //
//                                                                   //
///////////////////////////////////////////////////////////////////////


contract ButaversePass is ERC1155Creator {
    constructor() ERC1155Creator("ButaversePass", "ButaversePass") {}
}