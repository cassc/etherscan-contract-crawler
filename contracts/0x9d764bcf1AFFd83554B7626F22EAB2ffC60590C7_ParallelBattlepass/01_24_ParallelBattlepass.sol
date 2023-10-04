pragma solidity 0.8.17;
// SPDX-License-Identifier: MIT

import { ERC1155InvokeCutoff } from "../nfts/ERC1155InvokeCutoff.sol";

contract ParallelBattlepass is ERC1155InvokeCutoff {
    constructor()
        ERC1155InvokeCutoff(
            true,
            "https://nft-data.parallelnft.com/battlepass/{id}",
            "Parallel Battlepass",
            "LLBP"
        )
    {}
}