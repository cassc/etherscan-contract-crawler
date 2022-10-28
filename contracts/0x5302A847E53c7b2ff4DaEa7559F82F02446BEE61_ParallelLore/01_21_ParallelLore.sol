// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../nfts/ERC1155Invoke.sol";

/// @title The ParallelLore contract.
/// @notice Used for lore related nfts.
contract ParallelLore is ERC1155Invoke {
    constructor()
    ERC1155Invoke(
        "https://nftdata.parallelnft.com/api/parallel-lore/ipfs/",
        "ParallelLore",
        "LLLR"
    )
    {}
}