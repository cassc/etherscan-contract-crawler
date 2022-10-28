pragma solidity 0.8.7;
// SPDX-License-Identifier: MIT

import "../nfts/ERC1155Invoke.sol";

/// @title The ParallelComic contract.
/// @notice Used for parallel comic nfts.
contract ParallelComic is ERC1155Invoke {
    constructor()
    ERC1155Invoke(
        "https://nftdata.parallelnft.com/api/parallel-comics/ipfs/",
        "ParallelComics",
        "LLCMC"
    )
    {}
}