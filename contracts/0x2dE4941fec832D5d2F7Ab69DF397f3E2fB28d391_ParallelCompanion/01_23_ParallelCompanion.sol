// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../nfts/ERC1155InvokeCutoff.sol";

/// @title The ParallelCompanions contract.
/// @notice Used for companion nfts.
contract ParallelCompanion is ERC1155InvokeCutoff {
    constructor()
    ERC1155InvokeCutoff(
    true,
    "https://nftdata.parallelnft.com/api/parallel-companions/ipfs/",
    "ParallelCompanions",
    "LLCMP"
    )
    {}
}