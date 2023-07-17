// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Artifex Origins
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                   `syyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy-                   //
//                   `mMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN/                   //
//                   `mMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN/                   //
//                   `mMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN/                   //
//                   `mMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN/                   //
//                   `mMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN/                   //
//                   `mMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN/                   //
//                   `mMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN/                   //
//                   `mMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN/                   //
//                   `mMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN/                   //
//                   `mMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN/                   //
//                   `mMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN/                   //
//                   `mMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN/                   //
//                   `mMMMMMMMMMMMMMMMMMMMMMMMNMMNNNNNNNNNNNNNNNNNNNNNNNNNMMMMMMMMMMMMMMMN/                   //
//                   `mMMMMMMMMMMMMMMMMMMMMMMy/NMo.......................:dMMMMMMMMMMMMMMN/                   //
//                   `mMMMMMMMMMMMMMMMMMMMMMy` /NN/`````     ````    ````-dMMMMMMMMMMMMMMN/                   //
//                   `mMMMMMMMMMMMMMMMMMMMMy`   /NMNNNNNo   `yNNy`   /NNNNMMMMMMMMMMMMMMMN/                   //
//                   `mMMMMMMMMMMMMMMMMMMMh`     /NMmyyy:   `hMMh`   /MMMMMMMMMMMMMMMMMMMN/                   //
//                   `mMMMMMMMMMMMMMMMMMMy`   -   /mN/     -yMMMh`   /MMMMMMMMMMMMMMMMMMMN/                   //
//                   `mMMMMMMMMMMMMMMMMMy.  `sm:   /Nm/   `hMMMMh`   /MMMMMMMMMMMMMMMMMMMN/                   //
//                   `mMMMMMMMMMMMMMMMMy`  `sMMd-   /NN/   .hMMMh`   /MMMMMMMMMMMMMMMMMMMN/                   //
//                   `mMMMMMMMMMMMMMMMh.``.oNMMMd-```+NN/```-yMMh-```+MMMMMMMMMMMMMMMMMMMN/                   //
//                   `mMMMMMMMMMMMMMMMmmmdmMMMMMMNmmmmNMNmmmmmMMMmmmmNMMMMMMMMMMMMMMMMMMMN/                   //
//                   `mMMMMMMMMMMMMMMMMMMMMMMMMMMh///+dMm+////////////////////sNMMMdo///oN/                   //
//                   `mMMMMMMMMMMMMMMMMMMMMMMMMMMo   `yMd`                     :mMy.  `/mN/                   //
//                   `mMMMMMMMMMMMMMMMMMMMMMMMMMMo   `yMd`   :ooooo:   `osss:   -/`  `sNMN/                   //
//                   `mMMMMMMMMMMMMMMMMMMMMMMMMMMo   `yMd`   :ooomMo   `++oNNo.     -hMMMN/                   //
//                   `mMMMMMMMMMMMMMMMMMMMMMMMMMMo   `yMd`       dMo      `dMM+    .dMMMMN/                   //
//                   `mMMMMMMMMMMMMMMMMMMMMMMMMMMo   `yMd`   /sssNMo   `osyNN+`     -dMMMN/                   //
//                   `mMMMMMMMMMMMMMMMMMMMMMMMMMMo   `yMd`   yMMMMMo   `ooos-   -/`  `hMMN/                   //
//                   `mMMMMMMMMMMMMMMMMMMMMMMMMMMo   `yMd`   yMMMMMo           /mMh`  `+NN/                   //
//                   `mMMMMMMMMMMMMMMMMMMMMMMMMMMdoooodMNoooodMMMMMh++++++++++sMMMMd-   :d/                   //
//                   `mMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMm+   .-                   //
//                   `mMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM+`                      //
//                   `mMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMy.                     //
//                   `syyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy+`                    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ARTIFEXORIGINS is ERC1155Creator {
    constructor() ERC1155Creator() {}
}